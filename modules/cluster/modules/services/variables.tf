variable "infrastructure_name" {
}

variable "name" {
}

variable "container_definitions" {
}

variable "container_port" {
}

variable "api_keys" {
  type = list(string)
}

variable "aws_region" {
}

variable "aws_ecs_cluster_arn" {
}

variable "aws_alb_target_group_arn" {
}

variable "aws_ecs_service_desired_count" {
  default = 3
}

variable "aws_cloudwatch_log_group_name" {
}

