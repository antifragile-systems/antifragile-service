locals {
  hostname = "${var.name}.${var.domain}"
}

module "cluster" {
  source = "./modules/cluster"

  aws_region                 = "${var.aws_region}"
  domain                     = "${var.domain}"
  container_port             = "${var.container_port}"
  container_definitions_file = "${var.container_definitions_file}"
  infrastructure_name        = "${var.infrastructure_name}"
  name                       = "${var.name}"
  health_check_path          = "${var.health_check_path}"
  api_keys                   = "${var.api_keys}"
}

module "api" {
  source = "./modules/api"

  infrastructure_name             = "${var.infrastructure_name}"
  name                            = "${var.name}"
  domain                          = "${var.domain}"
  api_stage_name                  = "${var.api_stage_name}"
  api_quota_limit                 = "${var.api_quota_limit}"
  api_throttle_rate_limit         = "${var.api_throttle_rate_limit}"
  api_quota_offset                = "${var.api_quota_offset}"
  api_throttle_burst_limit        = "${var.api_throttle_burst_limit}"
  api_keys                        = "${var.api_keys}"
  api_quota_period                = "${var.api_quota_period}"
  aws_api_gateway_integration_uri = "http://${module.cluster.aws_lb_dns_name}/{proxy}"
}

module "monitor" {
  source = "./modules/monitor"

  infrastructure_name = "${var.infrastructure_name}"
  name                = "${var.name}"
}
