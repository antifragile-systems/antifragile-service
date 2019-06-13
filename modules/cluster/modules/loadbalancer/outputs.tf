output "aws_alb_target_group_arn" {
  value = aws_alb_target_group.antifragile-service.arn
}

output "aws_lb_dns_name" {
  value = data.aws_lb.selected.dns_name
}

