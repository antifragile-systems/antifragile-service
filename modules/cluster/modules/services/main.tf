module "tasks" {
  source                = "./modules/tasks"

  infrastructure_name   = "${var.infrastructure_name}"
  name                  = "${var.name}"
  container_port        = "${var.container_port}"
  container_definitions = "${var.container_definitions}"
  api_keys              = "${var.api_keys}"
  aws_region            = "${var.aws_region}"
}

data "aws_vpc" "antifragile-service" {
  tags {
    Name = "${var.infrastructure_name}"
  }
}

data "aws_subnet_ids" "antifragile-service" {
  vpc_id = "${data.aws_vpc.antifragile-service.id}"
}

resource "aws_security_group" "antifragile-service" {
  name        = "${var.infrastructure_name}.${var.name}"
  description = "${var.name} security group"
  vpc_id      = "${data.aws_vpc.antifragile-service.id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "antifragile-service" {
  type                     = "ingress"
  from_port                = "${var.container_port}"
  to_port                  = "${var.container_port}"
  protocol                 = "tcp"
  source_security_group_id = "${var.aws_alb_security_group_id}"
  security_group_id        = "${aws_security_group.antifragile-service.id}"
}

resource "aws_ecs_service" "antifragile-service" {
  name                               = "${var.name}"
  cluster                            = "${var.aws_ecs_cluster_arn}"
  task_definition                    = "${module.tasks.aws_ecs_task_definition_arn}"
  desired_count                      = 3
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 30

  load_balancer {
    target_group_arn = "${var.aws_alb_target_group_arn}"
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

  network_configuration {
    subnets         = [
      "${data.aws_subnet_ids.antifragile-service.ids}" ]
    security_groups = [
      "${aws_security_group.antifragile-service.id}" ]
  }
}
