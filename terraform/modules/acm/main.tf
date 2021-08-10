data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_route53_record" "current_region_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.current_region_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hostedzone_id
}

resource "aws_acm_certificate" "current_region_cert" {
  domain_name = var.domain
  subject_alternative_names = [
    "*.${var.domain}"
  ]
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}
