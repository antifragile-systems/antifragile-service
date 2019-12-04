output "aws_ecs_task_definition_arn" {
  value = aws_ecs_task_definition.antifragile-service.arn
}

output "aws_iam_role_name" {
  value = aws_iam_role.antifragile-service.name
}
