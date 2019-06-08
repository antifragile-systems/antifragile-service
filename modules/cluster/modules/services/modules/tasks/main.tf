locals {
  api_keys = "${join(",", var.api_keys)}"
}

data "aws_caller_identity" "current" {}

data "template_file" "container_definitions" {
  template = "${var.container_definitions}"

  vars {
    awslogs-group         = "${var.infrastructure_name}"
    awslogs-region        = "${var.aws_region}"
    awslogs-stream-prefix = "${var.name}"
    api_keys              = "${local.api_keys}"
  }
}

resource "aws_iam_role" "antifragile-service" {
  name = "${var.name}"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
              "Service": [
                  "ecs-tasks.amazonaws.com"
              ]
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

  tags = {
    IsAntifragile = true
  }
}

resource "aws_iam_role_policy_attachment" "antifragile-service" {
  role       = "${aws_iam_role.antifragile-service.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_kms_key" "antifragile-service" {
  key_id = "alias/aws/ssm"
}

data "template_file" "task_policy" {
  template = "${file("${path.module}/task-policy.json")}"

  vars {
    region     = "${var.aws_region}"
    account_id = "${data.aws_caller_identity.current.account_id}"

    infrastructure_name = "${var.infrastructure_name}"
    name                = "${var.name}"
    key_id              = "${data.aws_kms_key.antifragile-service.id}"
  }
}

resource "aws_iam_policy" "antifragile-service" {
  name = "${var.name}"

  policy = "${data.template_file.task_policy.rendered}"
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = "${aws_iam_role.antifragile-service.name}"
  policy_arn = "${aws_iam_policy.antifragile-service.arn}"
}

resource "aws_ecs_task_definition" "antifragile-service" {
  family                = "${var.name}"
  container_definitions = "${data.template_file.container_definitions.rendered}"
  network_mode          = "bridge"

  execution_role_arn = "${aws_iam_role.antifragile-service.arn}"

  volume {
    name      = "${var.name}"
    host_path = "/mnt/efs/${var.name}"
  }
}
