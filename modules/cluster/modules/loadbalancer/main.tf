locals {
  hostname = "${var.name}.${var.domain_name}"
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
    path                = "${var.name}/${var.health_check_path}"
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

resource "aws_alb_listener_rule" "antifragile-service-0" {
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

data "aws_lb_listener" "selected443" {
  load_balancer_arn = "${data.aws_lb.selected.arn}"
  port              = 443
}

resource "aws_alb_listener_rule" "antifragile-service-2" {
  listener_arn = "${data.aws_lb_listener.selected443.arn}"

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
  name = "${var.domain_name}."
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
