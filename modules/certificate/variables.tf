variable "enabled" {
  default = 0
}

variable "domain_name" {}

variable "subject_alternative_names" {
  type    = "list"
  default = [ ]
}
