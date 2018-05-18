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
