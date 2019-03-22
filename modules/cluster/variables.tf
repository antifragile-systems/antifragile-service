variable "infrastructure_name" {}

variable "name" {}

variable "container_definitions" {}

variable "health_check_path" {}

variable "health_check_path_preappend_name" {
  default = true
}

variable "container_port" {}

variable "api_keys" {
  type = "list"
}

variable "aws_region" {}

variable "aws_ecs_service_task_desired_count" {
  default = 3
}
