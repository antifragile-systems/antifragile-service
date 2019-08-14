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
    port                = "traffic-port"
    path                = local.health_check_path
    interval            = 5
  }
}

data "aws_lb" "selected" {
  name = var.infrastructure_name
}

