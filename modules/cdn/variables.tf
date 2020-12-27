variable "infrastructure_name" {
}

variable "infrastructure_bucket" {
}

variable "name" {
}

variable "enabled" {
  default = 0
}

variable "certificate_validation_enabled" {
  default = 1
}

variable "hostname" {
}

variable "hostname_aliases" {
  type    = list(string)
  default = []
}

variable "hostname_redirects" {
  type    = list(string)
  default = []
}

variable "aws_alb_target_group_arn" {
}

variable "aws_route53_health_check_request_interval" {
  default = 30
}

