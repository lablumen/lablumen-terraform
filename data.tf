# The hosted zone and ACM certificate are managed OUTSIDE Terraform (you created them manually).
# We only look them up by name/domain and create records dynamically — nothing here creates a zone
# or a certificate.
#
# Prerequisite: the ACM certificate must be ISSUED (validation complete) before apply, since CloudFront
# attaches it. The cert must live in us-east-1 (CloudFront requirement) — which is var.aws_region here.

# The account ID is DISCOVERED from the active credentials (never hardcoded). It drives globally-unique
# bucket names and the ECR registry URL, so the same code is portable across AWS accounts.
data "aws_caller_identity" "current" {}

data "aws_route53_zone" "primary" {
  name         = var.domain_name
  private_zone = false
}

data "aws_acm_certificate" "primary" {
  domain      = local.acm_domain
  statuses    = ["ISSUED"]
  most_recent = true
}
