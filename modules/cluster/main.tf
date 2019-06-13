module "loadbalancer" {
  source = "./modules/loadbalancer"

  infrastructure_name              = var.infrastructure_name
  name                             = var.name
  container_port                   = var.container_port
  health_check_path                = var.health_check_path
  health_check_path_preappend_name = var.health_check_path_preappend_name
  session_stickiness_enabled       = var.loadbalancer_session_stickiness_enabled
}

data "aws_ecs_cluster" "antifragile-service" {
  cluster_name = var.infrastructure_name
}

module "services" {
  source = "./modules/services"

  infrastructure_name           = var.infrastructure_name
  name                          = var.name
  container_port                = var.container_port
  container_definitions         = var.container_definitions
  api_keys                      = var.api_keys
  aws_region                    = var.aws_region
  aws_ecs_cluster_arn           = data.aws_ecs_cluster.antifragile-service.arn
  aws_alb_target_group_arn      = module.loadbalancer.aws_alb_target_group_arn
  aws_ecs_service_desired_count = var.service_desired_count
}

