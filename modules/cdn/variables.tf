variable "infrastructure_name" {}

variable "name" {}

variable "enabled" {
  default = 0
}

variable "cnames" {
  type    = "list"
  default = [ ]
}

variable "redirect_cname" {
  default = ""
}

variable "aws_alb_target_group_arn" {
}
