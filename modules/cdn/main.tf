data "aws_lb" "selected" {
  count = "${var.enabled}"

  name = "${var.infrastructure_name}"
}

resource "aws_cloudfront_distribution" "antifragile-service" {
  count = "${var.enabled}"

  enabled = true

  origin {
    domain_name = "${data.aws_lb.selected.dns_name}"
    origin_id   = "ELB-${data.aws_lb.selected.name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = [
        "TLSv1",
        "TLSv1.1",
        "TLSv1.2" ]
    }
  }

  aliases = [
    "${var.cnames}",
    "${var.redirect_cname}" ]

  is_ipv6_enabled = true

  default_cache_behavior {
    allowed_methods  = [
      "GET",
      "HEAD",
      "OPTIONS",
      "PUT",
      "POST",
      "PATCH",
      "DELETE" ]
    cached_methods   = [
      "GET",
      "HEAD" ]
    target_origin_id = "ELB-${data.aws_lb.selected.name}"

    forwarded_values {
      query_string = true
      headers      = [
        "Authorization",
        "CloudFront-Forwarded-Proto",
        "Host",
        "Origin",
        "Referer"
      ]

      cookies {
        forward = "all"
      }
    }

    compress = true

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "${module.certificate.aws_acm_certificate_arn}"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }
}

data "aws_lb_listener" "selected" {
  count = "${var.enabled}"

  load_balancer_arn = "${data.aws_lb.selected.arn}"
  port              = 80
}

resource "aws_alb_listener_rule" "antifragile-service" {
  count = "${var.enabled * length(var.cnames)}"

  listener_arn = "${data.aws_lb_listener.selected.arn}"

  action {
    type             = "forward"
    target_group_arn = "${var.aws_alb_target_group_arn}"
  }

  condition {
    field = "host-header"

    values = [
      "${element(var.cnames, count.index)}"
    ]
  }
}

resource "aws_alb_listener_rule" "antifragile-service-1" {
  count = "${(var.enabled && var.redirect_cname != "" && length(var.cnames) > 0) ? 1 : 0 }"

  listener_arn = "${data.aws_lb_listener.selected.arn}"

  action {
    type = "redirect"

    redirect {
      host        = "${element(var.cnames, 0)}"
      status_code = "HTTP_301"
    }
  }

  condition {
    field  = "host-header"
    values = [
      "${var.redirect_cname}" ]
  }
}

locals {
  cnames                  = [
    "${var.cnames}",
    "" ]
  certificate_domain_name = "${length(compact(local.cnames)) > 0 ? element(local.cnames, 0) : ""}"
}

module "certificate" {
  source = "../certificate"

  enabled = "${var.enabled}"

  domain_name               = "${local.certificate_domain_name}"
  subject_alternative_names = [
    "${var.redirect_cname}" ]
}

resource "aws_route53_health_check" "antifragile-service" {
  fqdn              = "${local.certificate_domain_name}"
  port              = 443
  type              = "HTTPS"
  request_interval  = 30
  failure_threshold = 3
}

resource "aws_cloudwatch_metric_alarm" "antifragile-service" {
  provider = "aws.global"

  alarm_name = "${local.certificate_domain_name} availability"

  metric_name = "HealthCheckStatus"
  namespace   = "AWS/Route53"

  dimensions {
    HealthCheckId = "${aws_route53_health_check.antifragile-service.id}"
  }

  threshold           = "1"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  period              = "60"
  statistic           = "Minimum"

  treat_missing_data = "breaching"
}
