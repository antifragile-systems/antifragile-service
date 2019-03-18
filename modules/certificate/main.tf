provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_acm_certificate" "antifragile-service" {
  domain_name               = "${var.domain_name}"
  subject_alternative_names = "${var.subject_alternative_names}"
  validation_method         = "DNS"
}
