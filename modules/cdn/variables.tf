variable "infrastructure_name" {}

variable "name" {}

variable "enabled" {
  default = 0
}

variable "cnames" {
  type    = "list"
  default = [ ]
}
