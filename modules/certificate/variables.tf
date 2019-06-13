variable "enabled" {
  default = 0
}

variable "validation_enabled" {
  default = 1
}

variable "domain_name" {
}

variable "subject_alternative_names" {
  type    = list(string)
  default = []
}

