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
  target_type          = "instance"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 4
    port                = "traffic-port"
    path                = "/${var.name}${var.health_check_path}"
    interval            = 5
  }
}

data "aws_lb" "selected" {
  name = "${var.infrastructure_name}"
}

data "aws_lb_listener" "selected" {
  load_balancer_arn = "${data.aws_lb.selected.arn}"
  port              = 80
}

resource "aws_alb_listener_rule" "antifragile-service" {
  listener_arn = "${data.aws_lb_listener.selected.arn}"

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.antifragile-service.arn}"
  }

  condition {
    field  = "path-pattern"

    values = [
      "/${var.name}/*",
    ]
  }
}

data "aws_security_group" "antifragile-service" {
  name = "${var.infrastructure_name}.loadbalancer"
}
