data "aws_api_gateway_rest_api" "antifragile-service" {
  name = "${var.infrastructure_name}"
}

resource "aws_api_gateway_resource" "antifragile-service-1" {
  rest_api_id = "${data.aws_api_gateway_rest_api.antifragile-service.id}"
  parent_id   = "${data.aws_api_gateway_rest_api.antifragile-service.root_resource_id}"
  path_part   = "${var.name}"
}

resource "aws_api_gateway_resource" "antifragile-service-2" {
  rest_api_id = "${data.aws_api_gateway_rest_api.antifragile-service.id}"
  parent_id   = "${aws_api_gateway_resource.antifragile-service-1.id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "antifragile-service" {
  rest_api_id      = "${data.aws_api_gateway_rest_api.antifragile-service.id}"
  resource_id      = "${aws_api_gateway_resource.antifragile-service-2.id}"
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = "${length(var.api_keys) > 0 ? true : false}"

  request_parameters {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "antifragile-service" {
  rest_api_id             = "${data.aws_api_gateway_rest_api.antifragile-service.id}"
  resource_id             = "${aws_api_gateway_resource.antifragile-service-2.id}"
  http_method             = "${aws_api_gateway_method.antifragile-service.http_method}"
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "${var.aws_api_gateway_integration_uri}"

  request_parameters {
    "integration.request.path.proxy"              = "method.request.path.proxy"
    "integration.request.header.X-Forwarded-Host" = "stageVariables.host"
    "integration.request.header.Accept-Encoding"  = "'identity'"
  }
}

resource "aws_api_gateway_usage_plan" "antifragile-service" {
  name = "${var.name}"

  api_stages {
    api_id = "${data.aws_api_gateway_rest_api.antifragile-service.id}"
    stage  = "${var.api_stage_name}"
  }

  quota_settings {
    limit  = "${var.api_quota_limit}"
    offset = "${var.api_quota_offset}"
    period = "${var.api_quota_period}"
  }

  throttle_settings {
    burst_limit = "${var.api_throttle_burst_limit}"
    rate_limit  = "${var.api_throttle_rate_limit}"
  }
}

resource "aws_api_gateway_api_key" "antifragile-service" {
  count = "${length(var.api_keys)}"

  name  = "${var.name}.${count.index}"
  value = "${element(var.api_keys, count.index)}"
}

resource "aws_api_gateway_usage_plan_key" "antifragile-service" {
  count = "${length(aws_api_gateway_api_key.antifragile-service.*.id)}"

  usage_plan_id = "${aws_api_gateway_usage_plan.antifragile-service.id}"

  key_id   = "${aws_api_gateway_api_key.antifragile-service.*.id[count.index]}"
  key_type = "API_KEY"
}

resource "aws_api_gateway_deployment" "antifragile-service" {
  depends_on = [
    "aws_api_gateway_integration.antifragile-service",
  ]

  rest_api_id = "${data.aws_api_gateway_rest_api.antifragile-service.id}"
  stage_name  = "${var.api_stage_name}"

  variables = {
    "deployed_at" = "${timestamp()}"
  }

  lifecycle {
    create_before_destroy = true
  }
}
