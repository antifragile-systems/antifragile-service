variable "infrastructure_name" {}

variable "name" {}

variable "enabled" {
  default = 0
}

variable "api_keys" {
  type = "list"
}

variable "api_quota_limit" {}

variable "api_quota_offset" {}

variable "api_quota_period" {}

variable "api_throttle_burst_limit" {}

variable "api_throttle_rate_limit" {}

variable "api_stage_name" {}

variable "aws_api_gateway_integration_uri" {}
