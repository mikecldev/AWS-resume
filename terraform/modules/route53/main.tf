# ============================================================================
# Route 53 Module - DNS Management (Optional)
# ============================================================================

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "website" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}
