variable "infrastructure_name" {
}

variable "name" {
}

variable "health_check_timeout" {
}

variable "health_check_interval" {
}

variable "health_check_path" {
}

variable "health_check_path_preappend_name" {
  default = true
}

variable "container_port" {
}

variable "session_stickiness_enabled" {
  default = false
}

