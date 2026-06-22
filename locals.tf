locals {
  cluster_name = "${var.project}-eks"

  # Tags applied to every resource via the provider default_tags block.
  common_tags = merge(var.tags, {
    Environment = var.environment
    Owner       = var.owner
  })

  # ACM cert domain to look up — defaults to a wildcard on the apex domain.
  acm_domain = coalesce(var.acm_certificate_domain, "*.${var.domain_name}")

  # Public hostnames derived from the (externally-owned) domain.
  frontend_fqdn = "${var.frontend_subdomain}.${var.domain_name}"
  api_fqdn      = "${var.api_subdomain}.${var.domain_name}"
}
