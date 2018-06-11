variable "infrastructure_name" {}

variable "name" {}

variable "domain_name" {}

variable "container_definitions_file" {}

variable "health_check_path" {}

variable "container_port" {}

variable "api_keys" {
  type = "list"
}

variable "aws_region" {}
