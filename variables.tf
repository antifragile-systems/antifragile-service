variable "infrastructure_name" {
  default = "antifragile-infrastructure"
}

variable "name" {}

variable "domain" {}

variable "container_definitions" {}

variable "health_check_path" {
  default = "/ping"
}

variable "container_port" {
  default = 3000
}

variable "api_key_required" {
  default = false
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
