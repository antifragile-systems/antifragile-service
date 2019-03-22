variable "infrastructure_name" {
  default = "antifragile-infrastructure"
}

variable "name" {}

variable "container_definitions" {}

variable "health_check_path" {
  default = "/ping"
}

variable "health_check_path_preappend_name" {
  default = true
}

variable "container_port" {
  default = 3000
}

variable "api_enabled" {
  default = 0
}

variable "api_keys" {
  type    = "list"
  default = []
}

variable "api_quota_limit" {
  default = 20
}

variable "api_quota_offset" {
  default = 2
}

variable "api_quota_period" {
  default = "WEEK"
}

variable "api_throttle_burst_limit" {
  default = 5
}

variable "api_throttle_rate_limit" {
  default = 10
}

variable "api_stage_name" {
  default = "production"
}

variable "cdn_enabled" {
  default = 0
}

variable "cdn_cnames" {
  type    = "list"
  default = [ ]
}

variable "cdn_redirect_cname" {
  default = ""
}

variable "aws_region" {
  default = "eu-west-1"
}

variable "task_desired_count" {
  default = 3
}
