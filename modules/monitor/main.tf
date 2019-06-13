data "aws_cloudwatch_log_group" "antifragile-service" {
  name = var.infrastructure_name
}

resource "aws_cloudwatch_log_stream" "antifragile-service" {
  name           = var.name
  log_group_name = data.aws_cloudwatch_log_group.antifragile-service.name
}

