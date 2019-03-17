locals {
  api_keys = "${join(",", var.api_keys)}"
}

data "template_file" "container_definitions" {
  template = "${var.container_definitions}"

  vars {
    awslogs-group         = "${var.infrastructure_name}"
    awslogs-region        = "${var.aws_region}"
    awslogs-stream-prefix = "${var.name}"
    api_keys              = "${local.api_keys}"
  }
}

resource "aws_ecs_task_definition" "antifragile-service" {
  family                = "${var.name}"
  container_definitions = "${data.template_file.container_definitions.rendered}"
  network_mode          = "bridge"

  volume {
    name      = "${var.name}"
    host_path = "/mnt/efs/${var.name}"
  }
}
