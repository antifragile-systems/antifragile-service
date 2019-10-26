locals {
  health_check_path = var.health_check_path_preappend_name ? format("/%s%s", var.name, var.health_check_path) : var.health_check_path
}

data "aws_vpc" "antifragile-service" {
  tags = {
    Name = var.infrastructure_name
  }
}

resource "aws_alb_target_group" "antifragile-service" {
  name                 = var.name
  port                 = var.container_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.antifragile-service.id
  deregistration_delay = 30
  target_type          = "instance"

  stickiness {
    type    = "lb_cookie"
    enabled = var.session_stickiness_enabled
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    port                = "traffic-port"
    path                = local.health_check_path
  }
}

data "aws_lb" "selected" {
  name = var.infrastructure_name
}

data "aws_sns_topic" "selected" {
  name = var.infrastructure_name
}

resource "aws_cloudwatch_metric_alarm" "antifragile-service" {
  alarm_name = "${var.name} healthy host count"

  metric_name = "HealthyHostCount"
  namespace   = "AWS/ApplicationELB"

  dimensions = {
    LoadBalancer = data.aws_lb.selected.arn_suffix
    TargetGroup  = aws_alb_target_group.antifragile-service.arn_suffix
  }

  threshold           = 0
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  period              = 60
  statistic           = "Average"
  treat_missing_data  = "breaching"

  alarm_actions = [
    data.aws_sns_topic.selected.arn,
  ]
  ok_actions    = [
    data.aws_sns_topic.selected.arn,
  ]
}
