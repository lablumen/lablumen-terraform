locals {
  cluster_name = "${var.project}-eks"

  # ---- Account-derived values (portability: nothing account-specific is hardcoded) ----
  account_id = data.aws_caller_identity.current.account_id

  # Globally-unique S3 bucket names. Default to a derived, account-suffixed name so a fresh account
  # "just works"; an explicit var override wins if you need a specific name.
  reports_bucket_name = coalesce(var.reports_bucket_name, "${var.project}-reports-${local.account_id}")
  state_bucket_name   = coalesce(var.state_bucket_name, "${var.project}-tfstate-${local.account_id}")
  sam_bucket_name     = "${var.project}-sam-${local.account_id}"


  # ECR registry base URL — consumed downstream (k8s global.imageRegistry / app CI). Derived, not pinned.
  image_registry = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"

  # Tags applied to every resource via the provider default_tags block.
  common_tags = merge(var.tags, {
    Environment = var.environment
    Owner       = var.owner
  })

  # ACM cert domain to look up — defaults to a wildcard on the apex domain.
  acm_domain = coalesce(var.acm_certificate_domain, "*.${var.domain_name}")

  # Public hostnames derived from the (externally-owned) domain.
  # frontend_fqdn feeds the k8s ingress host (values-dev/prod.yaml) and the ALB Route53 record.
  frontend_fqdn = "${var.frontend_subdomain}.${var.domain_name}"
  api_fqdn      = "${var.api_subdomain}.${var.domain_name}"

  # SES From address — local part + the domain (which is a verified SES domain identity).
  ses_from_address = "${var.ses_from_local_part}@${var.domain_name}"
}
