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
# S3 — reports bucket (KMS encrypted, versioned, private PHI store)
# ---------------------------------------------------------------------------
module "s3" {
  source = "./modules/s3"

  reports_bucket_name = local.reports_bucket_name
  tags                = local.common_tags
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
    "lablumen/app/database-url"  = "Full Postgres DSN incl. creds for service pods + ai_lambda. Compose from module.rds endpoint + the RDS-managed master secret."
    "lablumen/app/grafana-admin" = "Grafana admin creds as JSON {\"admin-user\":\"admin\",\"admin-password\":\"...\"}. Hand-populated; ESO syncs it into the monitoring namespace as the grafana-admin Secret."
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

  config = {
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
    "api-url"               = "https://${local.api_fqdn}"
  }
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
  backend_ecr_repository_arns = [for name, arn in module.ecr.repository_arns : arn if name != "lablumen/frontend"]
  frontend_ecr_repository_arn = module.ecr.repository_arns["lablumen/frontend"]

  # EKS / IRSA
  oidc_provider_arn       = module.eks.oidc_provider_arn
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  reports_bucket_arn      = module.s3.reports_bucket_arn
  queue_arn               = module.sqs.queue_arn
  ses_identity_arn        = module.ses.identity_arn
  route53_zone_arn        = data.aws_route53_zone.primary.arn

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# EKS access for the CI tf-apply role — Kubernetes cluster-admin (RBAC), SEPARATE from its AWS IAM
# admin. Lets the pipeline manage the kubernetes_* resources AND run the kubectl teardown in the
# destroy workflow. Standalone resource (depends on both module.eks + module.iam) to avoid a module
# dependency cycle. The cluster creator (whoever runs the first apply) already gets admin via
# enable_cluster_creator_admin_permissions, so this adds tf-apply without conflicting.
# ---------------------------------------------------------------------------
resource "aws_eks_access_entry" "tf_apply" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.iam.tf_apply_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "tf_apply_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.iam.tf_apply_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.tf_apply]
}
