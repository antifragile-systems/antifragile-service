output "aws_acm_certificate_arn" {
  value = var.enabled == 1 ? aws_acm_certificate.antifragile-service[ 0 ].arn : null
}

