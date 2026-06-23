# ---------------------------------------------------------------------------
# VPC — subnets, NAT GW, S3 gateway + interface endpoints
# ---------------------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  name             = var.project
  cidr             = var.vpc_cidr
  azs              = var.azs
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets
  cluster_name     = local.cluster_name
  tags             = local.common_tags
}

# ---------------------------------------------------------------------------
# EKS — control plane + managed node group + Karpenter + Access Entries
# ---------------------------------------------------------------------------
module "eks" {
  source = "./modules/eks"

  cluster_name                 = local.cluster_name
  cluster_version              = var.cluster_version
  vpc_id                       = module.vpc.vpc_id
  subnet_ids                   = module.vpc.private_subnets
  cluster_admin_access_entries = var.cluster_admin_access_entries
  node_instance_types          = var.node_instance_types
  node_min_size                = var.node_min_size
  node_max_size                = var.node_max_size
  node_desired_size            = var.node_desired_size
  tags                         = local.common_tags
}

# ---------------------------------------------------------------------------
# RDS — Postgres in isolated DB subnets, Secrets Manager-managed credentials
# ---------------------------------------------------------------------------
module "rds" {
  source = "./modules/rds"

  identifier           = "${var.project}-pg"
  engine_version       = var.db_engine_version
  family               = var.db_family
  major_engine_version = var.db_major_engine_version
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
  db_name              = var.db_name
  username             = var.db_username
  vpc_id               = module.vpc.vpc_id
  vpc_cidr             = var.vpc_cidr
  subnet_ids           = module.vpc.database_subnets
  tags                 = local.common_tags
}

# ---------------------------------------------------------------------------
# S3 — reports bucket (KMS) + frontend SPA bucket (private, CloudFront OAC)
# ---------------------------------------------------------------------------
module "s3" {
  source = "./modules/s3"

  reports_bucket_name  = local.reports_bucket_name
  frontend_bucket_name = local.frontend_bucket_name
  tags                 = local.common_tags
}

# ---------------------------------------------------------------------------
# CloudFront — SPA distribution (OAC → frontend bucket) + Route53 alias record
# ---------------------------------------------------------------------------
module "cloudfront" {
  source = "./modules/cloudfront"
  count  = var.enable_cloudfront ? 1 : 0

  name                                 = var.project
  aliases                              = [local.frontend_fqdn]
  frontend_bucket_id                   = module.s3.frontend_bucket_id
  frontend_bucket_arn                  = module.s3.frontend_bucket_arn
  frontend_bucket_regional_domain_name = module.s3.frontend_bucket_regional_domain_name
  acm_certificate_arn                  = data.aws_acm_certificate.primary.arn
  route53_zone_id                      = data.aws_route53_zone.primary.zone_id
  tags                                 = local.common_tags
}

# ---------------------------------------------------------------------------
# Lambda — AI processing function + S3 ObjectCreated trigger
# Gated OFF by default: Terraform does not build app code. The zip is produced by lablumen-app CI
# (Linux) and consumed as a prebuilt artifact when var.enable_ai_lambda is turned on.
# ---------------------------------------------------------------------------
module "lambda" {
  source = "./modules/lambda"
  count  = var.enable_ai_lambda ? 1 : 0

  function_name      = var.lambda_function_name
  source_path        = "${path.module}/../lablumen-app/serverless/ai-service"
  reports_bucket_id  = module.s3.reports_bucket_id
  reports_bucket_arn = module.s3.reports_bucket_arn
  tags               = local.common_tags
}

# ---------------------------------------------------------------------------
# SQS — notifications queue
# ---------------------------------------------------------------------------
module "sqs" {
  source = "./modules/sqs"

  queue_name = var.notifications_queue_name
  tags       = local.common_tags
}

# ---------------------------------------------------------------------------
# SES — verified sender identity
# ---------------------------------------------------------------------------
module "ses" {
  source = "./modules/ses"

  domain_name     = var.domain_name
  route53_zone_id = data.aws_route53_zone.primary.zone_id
  tags            = local.common_tags
}

# ---------------------------------------------------------------------------
# ECR — container image repositories (one per microservice)
# ---------------------------------------------------------------------------
module "ecr" {
  source = "./modules/ecr"

  repositories = var.ecr_repositories
  tags         = local.common_tags
}

# ---------------------------------------------------------------------------
# Cognito — user pool, SPA web client, role groups
# ---------------------------------------------------------------------------
module "cognito" {
  source = "./modules/cognito"

  project        = var.project
  user_pool_name = var.user_pool_name
  callback_urls  = ["https://${local.frontend_fqdn}/callback", "http://localhost:5173/callback"]
  logout_urls    = ["https://${local.frontend_fqdn}", "http://localhost:5173"]
  tags           = local.common_tags
}

# ---------------------------------------------------------------------------
# Secrets Manager — empty runtime secret shells (hand-populated out-of-band)
# ---------------------------------------------------------------------------
module "secretsmanager" {
  source = "./modules/secretsmanager"

  runtime_secrets = {
    "lablumen/app/database-url" = "Full Postgres DSN incl. creds for service pods + ai_lambda. Compose from module.rds endpoint + the RDS-managed master secret."
  }
  # Non-prod: purge immediately on destroy (0) instead of a 7-day recovery window. The 7-day window
  # blocks recreating a same-named secret, which trips re-applies on this frequently-rebuilt platform.
  # This is a re-populatable shell (no value stored by Terraform), so immediate purge is safe.
  secret_recovery_window_days = 0

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# SSM Parameter Store — non-sensitive runtime config
# ---------------------------------------------------------------------------
module "ssm" {
  source = "./modules/ssm"

  # cloudfront-distribution-id is only published when CloudFront is enabled (see var.enable_cloudfront);
  # merging it conditionally keeps module.ssm independent of the CloudFront resource.
  config = merge({
    "reports-bucket"        = module.s3.reports_bucket_id
    "sqs-url"               = module.sqs.queue_url
    "cognito-user-pool-id"  = module.cognito.user_pool_id
    "cognito-app-client-id" = module.cognito.app_client_id
    "ses-sender"            = local.ses_from_address
    "bedrock-embed-model"   = "amazon.titan-embed-text-v1"
    "bedrock-text-model"    = "amazon.nova-lite-v1:0"
    "region"                = var.aws_region
    "presigned-url-ttl"     = "3600"
    "cors-origins"          = "https://${local.frontend_fqdn},http://localhost:5173"

    # Frontend deploy discovery (single source of truth — the frontend-deploy CI job reads these at
    # runtime instead of duplicating them as GitHub variables).
    "frontend-bucket" = module.s3.frontend_bucket_id
    "api-url"         = "https://${local.api_fqdn}"
    }, var.enable_cloudfront ? {
    "cloudfront-distribution-id" = module.cloudfront[0].distribution_id
  } : {})
  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# IAM — GitHub OIDC + pipeline roles + IRSA roles (incl. external-dns)
# ---------------------------------------------------------------------------
module "iam" {
  source = "./modules/iam"

  project = var.project

  # CI/CD identity
  github_org                  = var.github_org
  state_bucket_name           = local.state_bucket_name
  ecr_repository_arns         = values(module.ecr.repository_arns)
  frontend_bucket_arn         = module.s3.frontend_bucket_arn
  cloudfront_distribution_arn = var.enable_cloudfront ? module.cloudfront[0].distribution_arn : null

  # EKS / IRSA
  oidc_provider_arn       = module.eks.oidc_provider_arn
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  reports_bucket_arn      = module.s3.reports_bucket_arn
  queue_arn               = module.sqs.queue_arn
  ses_identity_arn        = module.ses.identity_arn
  route53_zone_arn        = data.aws_route53_zone.primary.arn

  tags = local.common_tags
}
