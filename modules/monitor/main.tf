resource "aws_cloudwatch_log_group" "antifragile-service" {
  name              = "/${var.infrastructure_name}/${var.name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_metric_filter" "antifragile-service" {
  name           = "ErrorCountFilter"
  pattern        = "?\"ERROR\" ?\"Error\" ?\"error\""
  log_group_name = aws_cloudwatch_log_group.antifragile-service.name

  metric_transformation {
    name      = "ErrorCount"
    namespace = var.name
    value     = "1"
  }
}

data "aws_sns_topic" "selected" {
  name = var.infrastructure_name
}

resource "aws_cloudwatch_metric_alarm" "antifragile-service" {
  alarm_name = "${var.name} error count"

  metric_name = aws_cloudwatch_log_metric_filter.antifragile-service.metric_transformation[ 0 ].name
  namespace   = aws_cloudwatch_log_metric_filter.antifragile-service.metric_transformation[ 0 ].namespace

  threshold           = 3
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  period              = 60
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    data.aws_sns_topic.selected.arn,
  ]
  ok_actions    = [
    data.aws_sns_topic.selected.arn,
  ]
}
