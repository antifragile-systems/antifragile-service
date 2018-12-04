output "aws_alb_target_group_arn" {
  value = "${aws_alb_target_group.antifragile-service.arn}"
}

output "aws_lb_dns_name" {
  value = "${data.aws_lb.selected.dns_name}"
}

output "aws_alb_security_group_id" {
  value = "${data.aws_security_group.antifragile-service.id}"
}
