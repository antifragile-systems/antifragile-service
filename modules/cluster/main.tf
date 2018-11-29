locals {
  api_keys = "${join(",", var.api_keys)}"
}

module "loadbalancer" {
  source              = "./modules/loadbalancer"

  infrastructure_name = "${var.infrastructure_name}"
  name                = "${var.name}"
  container_port      = "${var.container_port}"
  health_check_path   = "${var.health_check_path}"
}

data "template_file" "container_definitions" {
  template = "${var.container_definitions}"

  vars {
    awslogs-group         = "${var.infrastructure_name}"
    awslogs-region        = "${var.aws_region}"
    awslogs-stream-prefix = "antifragile-service"
    api_keys              = "${local.api_keys}"
  }
}

resource "aws_ecs_task_definition" "antifragile-service" {
  family                = "${var.name}"
  container_definitions = "${data.template_file.container_definitions.rendered}"
}

data "aws_iam_role" "antifragile-service" {
  name = "${var.infrastructure_name}.ECSServiceRole"
}

data "aws_ecs_cluster" "antifragile-service" {
  cluster_name = "${var.infrastructure_name}"
}

resource "aws_ecs_service" "antifragile-service" {
  name                               = "${var.name}"
  cluster                            = "${data.aws_ecs_cluster.antifragile-service.arn}"
  task_definition                    = "${aws_ecs_task_definition.antifragile-service.arn}"
  iam_role                           = "${data.aws_iam_role.antifragile-service.id}"
  desired_count                      = 3
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 30

  load_balancer {
    target_group_arn = "${module.loadbalancer.aws_alb_target_group_arn}"
    container_name   = "${var.name}"
    container_port   = "${var.container_port}"
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }
}
