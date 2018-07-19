variable "infrastructure_name" {}

variable "name" {}

variable "container_definitions" {}

variable "health_check_path" {}

variable "container_port" {}

variable "api_keys" {
  type = "list"
}

variable "aws_region" {}
