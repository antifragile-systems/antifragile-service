provider "aws" {
  region  = "${var.aws_region}"
  version = "1.50"
}

provider "aws" {
  alias  = "global"
  region = "us-east-1"
}

provider "template" {
  version = "1.0.0"
}

module "cluster" {
  source = "./modules/cluster"

  aws_region                       = "${var.aws_region}"
  service_desired_count            = "${var.service_desired_count}"
  container_port                   = "${var.container_port}"
  container_definitions            = "${var.container_definitions}"
  infrastructure_name              = "${var.infrastructure_name}"
  name                             = "${var.name}"
  health_check_path                = "${var.health_check_path}"
  health_check_path_preappend_name = "${var.health_check_path_preappend_name}"
  api_keys                         = "${var.api_keys}"
}

module "api" {
  source = "./modules/api"

  enabled = "${var.api_enabled}"

  infrastructure_name             = "${var.infrastructure_name}"
  name                            = "${var.name}"
  api_stage_name                  = "${var.api_stage_name}"
  api_quota_limit                 = "${var.api_quota_limit}"
  api_throttle_rate_limit         = "${var.api_throttle_rate_limit}"
  api_quota_offset                = "${var.api_quota_offset}"
  api_throttle_burst_limit        = "${var.api_throttle_burst_limit}"
  api_keys                        = "${var.api_keys}"
  api_quota_period                = "${var.api_quota_period}"
  aws_api_gateway_integration_uri = "http://${module.cluster.aws_lb_dns_name}/${var.name}/{proxy}"
}

module "cdn" {
  source = "./modules/cdn"

  enabled = "${var.cdn_enabled}"

  certificate_validation_enabled = "${var.cdn_certificate_validation_enabled}"

  infrastructure_name      = "${var.infrastructure_name}"
  name                     = "${var.name}"
  hostname                 = "${var.cdn_hostname}"
  hostname_aliases         = "${var.cdn_hostname_aliases}"
  hostname_redirects       = "${var.cdn_hostname_redirects}"
  aws_alb_target_group_arn = "${module.cluster.aws_alb_target_group_arn}"
}

module "monitor" {
  source = "./modules/monitor"

  infrastructure_name = "${var.infrastructure_name}"
  name                = "${var.name}"
}
