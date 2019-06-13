provider "aws" {
  alias = "global"
}

data "aws_api_gateway_rest_api" "antifragile-service" {
  count = var.enabled

  name = var.infrastructure_name
}

resource "aws_api_gateway_resource" "antifragile-service-1" {
  count = var.enabled

  rest_api_id = data.aws_api_gateway_rest_api.antifragile-service[0].id
  parent_id   = data.aws_api_gateway_rest_api.antifragile-service[0].root_resource_id
  path_part   = var.name
}

resource "aws_api_gateway_resource" "antifragile-service-2" {
  count = var.enabled

  rest_api_id = data.aws_api_gateway_rest_api.antifragile-service[0].id
  parent_id   = aws_api_gateway_resource.antifragile-service-1[0].id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "antifragile-service" {
  count = var.enabled

  rest_api_id      = data.aws_api_gateway_rest_api.antifragile-service[0].id
  resource_id      = aws_api_gateway_resource.antifragile-service-2[0].id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = length(var.api_keys) > 0 ? true : false

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "antifragile-service" {
  count = var.enabled

  rest_api_id             = data.aws_api_gateway_rest_api.antifragile-service[0].id
  resource_id             = aws_api_gateway_resource.antifragile-service-2[0].id
  http_method             = aws_api_gateway_method.antifragile-service[0].http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = var.aws_api_gateway_integration_uri

  request_parameters = {
    "integration.request.path.proxy"              = "method.request.path.proxy"
    "integration.request.header.X-Forwarded-Host" = "stageVariables.host"
    "integration.request.header.Accept-Encoding"  = "'identity'"
  }
}

resource "aws_api_gateway_usage_plan" "antifragile-service" {
  count = var.enabled

  name = var.name

  api_stages {
    api_id = data.aws_api_gateway_rest_api.antifragile-service[0].id
    stage  = var.api_stage_name
  }

  quota_settings {
    limit  = var.api_quota_limit
    offset = var.api_quota_offset
    period = var.api_quota_period
  }

  throttle_settings {
    burst_limit = var.api_throttle_burst_limit
    rate_limit  = var.api_throttle_rate_limit
  }
}

resource "aws_api_gateway_api_key" "antifragile-service" {
  count = var.enabled * length(var.api_keys)

  name  = "${var.name}.${count.index}"
  value = element(var.api_keys, count.index)
}

resource "aws_api_gateway_usage_plan_key" "antifragile-service" {
  count = var.enabled * length(var.api_keys)

  usage_plan_id = aws_api_gateway_usage_plan.antifragile-service[0].id

  key_id   = aws_api_gateway_api_key.antifragile-service[count.index].id
  key_type = "API_KEY"
}

resource "aws_api_gateway_deployment" "antifragile-service" {
  count = var.enabled

  depends_on = [aws_api_gateway_integration.antifragile-service]

  rest_api_id = data.aws_api_gateway_rest_api.antifragile-service[0].id
  stage_name  = var.api_stage_name

  variables = {
    "deployed_at" = timestamp()
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_alb_target_group" "selected" {
  count = var.enabled

  name = var.name
}

data "aws_lb" "selected" {
  count = var.enabled

  name = var.infrastructure_name
}

data "aws_lb_listener" "selected" {
  count = var.enabled

  load_balancer_arn = data.aws_lb.selected[0].arn
  port              = 80
}

resource "aws_alb_listener_rule" "antifragile-service" {
  count = var.enabled

  listener_arn = data.aws_lb_listener.selected[0].arn

  action {
    type             = "forward"
    target_group_arn = data.aws_alb_target_group.selected[0].arn
  }

  condition {
    field = "path-pattern"

    values = [
      "/${var.name}/*",
    ]
  }
}

