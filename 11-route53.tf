############################################
# Bonus B - Route53 (Hosted Zone + DNS records + ACM validation + ALIAS to ALB)
############################################

############################################
# Hosted Zone (optional creation)
############################################

# Explanatio# Create hosted zone only if you want Terraform to manage it
resource "aws_route53_zone" "passportpookie" {
  count = var.manage_route53_in_terraform ? 1 : 0
  name  = local.zone_name

  tags = merge(local.tags, {
    Name = "${var.project_name}-zone"
  })
}

# Otherwise, read the existing hosted zone by ID
data "aws_route53_zone" "passportpookie_existing" {
  count   = var.manage_route53_in_terraform ? 0 : 1
  zone_id = "Z09361711HDESSBG6MZ22"
}


############################################
# ACM DNS Validation Records
############################################

# Explanation: ACM asks “prove you own this planet”—DNS validation is lab2 roaring in the right place.
resource "aws_route53_record" "lab2_acm_validation_records01" {
  for_each = {
    for dvo in aws_acm_certificate.lab2_acm_cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = local.passportpookie_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60

  records = [each.value.record]
}

# Explanation: This ties the “proof record” back to ACM—lab2 gets his green checkmark for TLS.
resource "aws_acm_certificate_validation" "lab2_acm_validation" {
  certificate_arn         = aws_acm_certificate.lab2_acm_cert.arn
  validation_record_fqdns = [for r in aws_route53_record.lab2_acm_validation_records01 : r.fqdn]
}

############################################
# ALIAS record: app.lab2-growl.com -> ALB
############################################
/*
# Explanation: This is the holographic sign outside the cantina—app.lab2-growl.com points to your ALB.
resource "aws_route53_record" "lab2_app_alias" {
  zone_id = "Z09361711HDESSBG6MZ22"
  name    = local.app_subdomain
  type    = "A"

  alias {
    name                   = aws_lb.lab2_alb.dns_name
    zone_id                = aws_lb.lab2_alb.zone_id
    evaluate_target_health = true
  }
}
*/
