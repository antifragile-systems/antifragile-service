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

  aliases = "${var.cnames}"

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
        "*" ]

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
    cloudfront_default_certificate = true
  }
}

data "aws_alb_target_group" "selected" {
  count = "${var.enabled}"

  name = "${var.name}"
}

data "aws_lb_listener" "selected" {
  count = "${var.enabled}"

  load_balancer_arn = "${data.aws_lb.selected.arn}"
  port              = 80
}

resource "aws_alb_listener_rule" "antifragile-service" {
  count = "${var.enabled}"

  listener_arn = "${data.aws_lb_listener.selected.arn}"

  action {
    type             = "forward"
    target_group_arn = "${data.aws_alb_target_group.selected.arn}"
  }

  condition {
    field = "host-header"

    values = "${var.cnames}"
  }
}
