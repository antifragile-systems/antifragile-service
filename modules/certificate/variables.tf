variable "domain_name" {}

variable "subject_alternative_names" {
  type    = "list"
  default = [ ]
}

variable "aws_region" {
  default = "us-east-1"
}
