locals {
  hostname = "${var.name}.${var.domain}"
}

resource "aws_iam_role" "antifragile-service" {
  name_prefix        = "${var.infrastructure_name}."
  assume_role_policy = "${file("${path.module}/ecs-service-role.json")}"
}

resource "aws_iam_role_policy" "antifragile-service" {
  name_prefix = "${var.infrastructure_name}."
  policy      = "${file("${path.module}/ecs-service-role-policy.json")}"
  role        = "${aws_iam_role.antifragile-service.id}"
}

data "aws_vpc" "antifragile-service" {
  tags {
    Name = "${var.infrastructure_name}"
  }
}

resource "aws_alb_target_group" "antifragile-service" {
  name                 = "${var.name}"
  port                 = "${var.container_port}"
  protocol             = "HTTP"
  vpc_id               = "${data.aws_vpc.antifragile-service.id}"
  deregistration_delay = 30

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 4
    port                = "traffic-port"
    path                = "${var.health_check_path}"
    interval            = 5
  }
}

data "aws_lb" "selected" {
  name = "${var.infrastructure_name}"
}

data "aws_lb_listener" "selected80" {
  load_balancer_arn = "${data.aws_lb.selected.arn}"
  port              = 80
}

resource "aws_alb_listener_rule" "antifragile-service" {
  listener_arn = "${data.aws_lb_listener.selected80.arn}"

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.antifragile-service.arn}"
  }

  condition {
    field = "host-header"

    values = [
      "${local.hostname}",
    ]
  }
}

data "aws_route53_zone" "selected" {
  name = "${var.domain}."
}

resource "aws_route53_record" "antifragile-service" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${local.hostname}"
  type    = "CNAME"
  ttl     = "300"

  records = [
    "${data.aws_lb.selected.dns_name}",
  ]
}

data "aws_cloudwatch_log_group" "antifragile-service" {
  name = "${var.infrastructure_name}"
}

resource "aws_cloudwatch_log_stream" "antifragile-service" {
  name           = "${var.name}"
  log_group_name = "${data.aws_cloudwatch_log_group.antifragile-service.name}"
}

resource "aws_ecs_task_definition" "antifragile-service" {
  family                = "${var.name}"
  container_definitions = "${var.container_definitions}"
}

data "aws_ecs_cluster" "antifragile-service" {
  cluster_name = "${var.infrastructure_name}"
}

resource "aws_ecs_service" "antifragile-service" {
  name                               = "${var.name}"
  cluster                            = "${data.aws_ecs_cluster.antifragile-service.arn}"
  task_definition                    = "${aws_ecs_task_definition.antifragile-service.arn}"
  iam_role                           = "${aws_iam_role.antifragile-service.id}"
  desired_count                      = 3
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 30

  depends_on = [
    "aws_iam_role_policy.antifragile-service",
  ]

  load_balancer {
    target_group_arn = "${aws_alb_target_group.antifragile-service.arn}"
    container_name   = "${var.name}"
    container_port   = "${var.container_port}"
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }

  /*  lifecycle {
      ignore_changes = [
        "task_definition",
      ]
    }*/
}

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
  api_key_required = true

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
  uri                     = "http://${data.aws_lb.selected.dns_name}/{proxy}"

  request_parameters {
    "integration.request.path.proxy"  = "method.request.path.proxy"
    "integration.request.header.Host" = "'${var.name}.${var.domain}'"
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
  name = "${var.name}"
}

resource "aws_api_gateway_usage_plan_key" "antifragile-service" {
  usage_plan_id = "${aws_api_gateway_usage_plan.antifragile-service.id}"

  key_id   = "${aws_api_gateway_api_key.antifragile-service.id}"
  key_type = "API_KEY"
}

resource "aws_api_gateway_deployment" "antifragile-service" {
  depends_on = [
    "aws_api_gateway_integration.antifragile-service",
  ]

  rest_api_id = "${data.aws_api_gateway_rest_api.antifragile-service.id}"
  stage_name  = "${var.api_stage_name}"
}
