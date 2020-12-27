terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = "2.14.0"

  region = var.aws_region
}

provider "aws" {
  version = "2.14.0"

  alias  = "global"
  region = "us-east-1"
}

provider "template" {
  version = "2.1.2"
}

module "cluster" {
  source = "./modules/cluster"

  aws_region                              = var.aws_region
  service_desired_count                   = var.service_desired_count
  container_port                          = var.container_port
  container_definitions                   = var.container_definitions
  infrastructure_name                     = var.infrastructure_name
  name                                    = var.name
  health_check_timeout                    = var.health_check_timeout
  health_check_interval                   = var.health_check_interval
  health_check_path                       = var.health_check_path
  health_check_path_preappend_name        = var.health_check_path_preappend_name
  api_keys                                = var.api_keys
  loadbalancer_session_stickiness_enabled = var.loadbalancer_session_stickiness_enabled
  aws_cloudwatch_log_group_name           = module.monitor.aws_cloudwatch_log_group_name
}

module "api" {
  source = "./modules/api"

  enabled = var.api_enabled

  infrastructure_name             = var.infrastructure_name
  name                            = var.name
  api_stage_name                  = var.api_stage_name
  api_quota_limit                 = var.api_quota_limit
  api_throttle_rate_limit         = var.api_throttle_rate_limit
  api_quota_offset                = var.api_quota_offset
  api_throttle_burst_limit        = var.api_throttle_burst_limit
  api_keys                        = var.api_keys
  api_quota_period                = var.api_quota_period
  aws_api_gateway_integration_uri = "http://${module.cluster.aws_lb_dns_name}/${var.name}/{proxy}"
}

module "cdn" {
  source = "./modules/cdn"

  providers = {
    aws.global = aws.global
  }

  enabled = var.cdn_enabled

  certificate_validation_enabled = var.cdn_certificate_validation_enabled

  infrastructure_name                       = var.infrastructure_name
  infrastructure_bucket                     = var.infrastructure_bucket
  name                                      = var.name
  hostname                                  = var.cdn_hostname
  hostname_aliases                          = var.cdn_hostname_aliases
  hostname_redirects                        = var.cdn_hostname_redirects
  aws_alb_target_group_arn                  = module.cluster.aws_alb_target_group_arn
  aws_route53_health_check_request_interval = var.cdn_health_check_request_interval
}

module "monitor" {
  source = "./modules/monitor"

  infrastructure_name = var.infrastructure_name
  name                = var.name
}

