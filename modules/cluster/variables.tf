variable "infrastructure_name" {
}

variable "name" {
}

variable "container_definitions" {
}

variable "health_check_timeout" {
}

variable "health_check_interval" {
}

variable "health_check_path" {
}

variable "health_check_path_preappend_name" {
  default = true
}

variable "container_port" {
}

variable "api_keys" {
  type = list(string)
}

variable "aws_region" {
}

variable "service_desired_count" {
  default = 3
}

variable "loadbalancer_session_stickiness_enabled" {
  default = false
}


variable "aws_cloudwatch_log_group_name" {
}
