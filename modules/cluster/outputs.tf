output "aws_lb_dns_name" {
  value = module.loadbalancer.aws_lb_dns_name
}

output "aws_alb_target_group_arn" {
  value = module.loadbalancer.aws_alb_target_group_arn
}

output "aws_iam_role_name" {
  value = module.services.aws_iam_role_name
}
