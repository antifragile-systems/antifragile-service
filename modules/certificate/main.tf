resource "aws_acm_certificate" "antifragile-service" {
  provider = "aws.global"

  count = "${var.enabled}"

  domain_name               = "${var.domain_name}"
  subject_alternative_names = "${var.subject_alternative_names}"
  validation_method         = "DNS"
}

data "aws_route53_zone" "selected" {
  count = "${var.enabled * var.validation_enabled}"

  name         = "${var.domain_name}."
  private_zone = false
}

resource "aws_route53_record" "antifragile-service" {
  count = "${var.enabled * var.validation_enabled}"

  name    = "${aws_acm_certificate.antifragile-service.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.antifragile-service.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.selected.id}"

  records = [
    "${aws_acm_certificate.antifragile-service.domain_validation_options.0.resource_record_value}",
  ]

  ttl = 60
}

resource "aws_acm_certificate_validation" "antifragile-service" {
  count = "${var.enabled * var.validation_enabled}"

  provider = "aws.global"

  certificate_arn = "${aws_acm_certificate.antifragile-service.arn}"

  validation_record_fqdns = [
    "${aws_route53_record.antifragile-service.fqdn}",
  ]
}

