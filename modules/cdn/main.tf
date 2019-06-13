provider "aws" {
  alias = "global"
}

locals {
  hostname_domain_levels = length(split(".", var.hostname))
  hostname_domain_name = local.hostname_domain_levels > 1 ? join(
    ".",
    slice(
      split(".", var.hostname),
      local.hostname_domain_levels - 2,
      local.hostname_domain_levels
    )
  ) : var.hostname
}

data "aws_lb" "selected" {
  count = var.enabled

  name = var.infrastructure_name
}

resource "aws_cloudfront_distribution" "antifragile-service" {
  count = var.enabled

  enabled = true

  origin {
    domain_name = data.aws_lb.selected[0].dns_name
    origin_id   = "ELB-${data.aws_lb.selected[0].name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = [
        "TLSv1",
        "TLSv1.1",
        "TLSv1.2",
      ]
    }
  }

  aliases = concat([var.hostname], var.hostname_aliases, var.hostname_redirects)

  is_ipv6_enabled = true

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
      "PUT",
      "POST",
      "PATCH",
      "DELETE",
    ]
    cached_methods = [
      "GET",
      "HEAD",
    ]
    target_origin_id = "ELB-${data.aws_lb.selected[0].name}"

    forwarded_values {
      query_string = true
      headers = [
        "Authorization",
        "CloudFront-Forwarded-Proto",
        "Host",
        "Origin",
        "Referer",
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
    acm_certificate_arn      = module.certificate.aws_acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }
}

data "aws_lb_listener" "selected" {
  count = var.enabled

  load_balancer_arn = data.aws_lb.selected[0].arn
  port              = 80
}

resource "aws_alb_listener_rule" "antifragile-service" {
  count = var.enabled * length(concat([var.hostname], var.hostname_aliases))

  listener_arn = data.aws_lb_listener.selected[0].arn

  action {
    type             = "forward"
    target_group_arn = var.aws_alb_target_group_arn
  }

  condition {
    field = "host-header"

    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibilty in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    values = [
      element(concat([var.hostname], var.hostname_aliases), count.index),
    ]
  }
}

resource "aws_alb_listener_rule" "antifragile-service-1" {
  count = var.enabled * length(var.hostname_redirects)

  listener_arn = data.aws_lb_listener.selected[0].arn

  action {
    type = "redirect"

    redirect {
      host        = var.hostname
      status_code = "HTTP_301"
    }
  }

  condition {
    field = "host-header"
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibilty in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    values = [
      element(var.hostname_redirects, count.index),
    ]
  }
}

module "certificate" {
  source = "../certificate"

  providers = {
    aws.global = aws.global
  }

  enabled = var.enabled

  validation_enabled = var.certificate_validation_enabled

  domain_name               = var.hostname
  subject_alternative_names = concat(var.hostname_aliases, var.hostname_redirects)
}

resource "aws_route53_health_check" "antifragile-service" {
  fqdn              = var.hostname
  port              = 443
  type              = "HTTPS"
  request_interval  = var.aws_route53_health_check_request_interval
  failure_threshold = 3
}

data "aws_sns_topic" "selected" {
  provider = aws.global

  name = var.infrastructure_name
}

resource "aws_cloudwatch_metric_alarm" "antifragile-service" {
  provider = aws.global

  alarm_name = "${var.hostname} availability"

  metric_name = "HealthCheckStatus"
  namespace   = "AWS/Route53"

  dimensions = {
    HealthCheckId = aws_route53_health_check.antifragile-service.id
  }

  threshold           = "1"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  period              = "60"
  statistic           = "Minimum"

  treat_missing_data = "breaching"

  alarm_actions = [
    data.aws_sns_topic.selected.arn,
  ]
  ok_actions = [
    data.aws_sns_topic.selected.arn,
  ]
}

data "aws_route53_zone" "selected" {
  count = var.enabled

  name         = "${local.hostname_domain_name}."
  private_zone = false
}

resource "aws_route53_record" "antifragile-infrastructure" {
  count = var.enabled

  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = var.hostname
  type    = "A"

  alias {
    name    = aws_cloudfront_distribution.antifragile-service[0].domain_name
    zone_id = aws_cloudfront_distribution.antifragile-service[0].hosted_zone_id

    evaluate_target_health = false
  }
}

