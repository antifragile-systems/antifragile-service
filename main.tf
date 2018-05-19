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

  lifecycle {
    ignore_changes = [
      "task_definition",
    ]
  }
}
