provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

locals {
  cluster_name = "${var.project}-eks"
}

# ---------------------------------------------------------------------------
# Network — VPC, subnets, NAT GW, VPC endpoints (region-dynamic)
# ---------------------------------------------------------------------------
module "network" {
  source = "./modules/network"

  name             = var.project
  cidr             = var.vpc_cidr
  azs              = var.azs
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets
  cluster_name     = local.cluster_name
  tags             = var.tags
}

# ---------------------------------------------------------------------------
# EKS — control plane + managed node group + Karpenter
# ---------------------------------------------------------------------------
module "eks" {
  source = "./modules/eks"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.network.vpc_id
  subnet_ids      = module.network.private_subnets
  tags            = var.tags
}

# ---------------------------------------------------------------------------
# Data — RDS Postgres (isolated DB-tier subnets, SM-managed credentials)
# ---------------------------------------------------------------------------
module "data" {
  source = "./modules/data"

  identifier           = "${var.project}-pg"
  engine_version       = var.db_engine_version
  family               = var.db_family
  major_engine_version = var.db_major_engine_version
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
  db_name              = var.db_name
  username             = var.db_username
  vpc_id               = module.network.vpc_id
  vpc_cidr             = var.vpc_cidr
  subnet_ids           = module.network.database_subnets
  tags                 = var.tags
}

# ---------------------------------------------------------------------------
# Storage — private KMS-encrypted S3 bucket for report PDFs
# ---------------------------------------------------------------------------
module "storage" {
  source = "./modules/storage"

  reports_bucket_name = var.reports_bucket_name
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# Lambda — AI processing function + S3 ObjectCreated trigger
# ---------------------------------------------------------------------------
module "lambda" {
  source = "./modules/lambda"

  function_name      = var.lambda_function_name
  source_path        = "${path.module}/../lablumen-app/serverless/ai-service"
  reports_bucket_id  = module.storage.reports_bucket_id
  reports_bucket_arn = module.storage.reports_bucket_arn
  tags               = var.tags
}

# ---------------------------------------------------------------------------
# Messaging — SQS notifications queue + SES v2 sender identity
# ---------------------------------------------------------------------------
module "messaging" {
  source = "./modules/messaging"

  queue_name       = var.notifications_queue_name
  ses_sender_email = var.ses_sender_email
  tags             = var.tags
}

# ---------------------------------------------------------------------------
# ECR — container image repositories (one per microservice)
# ---------------------------------------------------------------------------
module "ecr" {
  source = "./modules/ecr"

  repositories = var.ecr_repositories
  tags         = var.tags
}

# ---------------------------------------------------------------------------
# Cognito — user pool, SPA web client, role groups
# ---------------------------------------------------------------------------
module "cognito" {
  source = "./modules/cognito"

  project        = var.project
  user_pool_name = var.user_pool_name
  tags           = var.tags
}

# ---------------------------------------------------------------------------
# IRSA — IAM roles for EKS service accounts (ESO, report-service, etc.)
# ---------------------------------------------------------------------------
module "irsa" {
  source = "./modules/irsa"

  project                 = var.project
  oidc_provider_arn       = module.eks.oidc_provider_arn
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  reports_bucket_arn      = module.storage.reports_bucket_arn
  queue_arn               = module.messaging.queue_arn
  ses_sender_email        = var.ses_sender_email
  tags                    = var.tags
}

# ---------------------------------------------------------------------------
# Secrets — Secrets Manager namespace containers + SSM config params
# ---------------------------------------------------------------------------
module "secrets" {
  source = "./modules/secrets"

  runtime_secrets = {
    "lablumen/app/database-url" = "Full Postgres DSN incl. creds for service pods + ai_lambda. Compose from module.data endpoint + the RDS-managed master secret."
  }

  ssm_config = {
    "reports-bucket"        = module.storage.reports_bucket_id
    "sqs-url"               = module.messaging.queue_url
    "cognito-user-pool-id"  = module.cognito.user_pool_id
    "cognito-app-client-id" = module.cognito.app_client_id
    "ses-sender"            = var.ses_sender_email
    "bedrock-embed-model"   = "amazon.titan-embed-text-v1"
    "bedrock-text-model"    = "amazon.nova-lite-v1:0"
    "region"                = var.aws_region
    "presigned-url-ttl"     = "3600"
    "cors-origins"          = "http://localhost:5173"
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# moved{} blocks — rename module.identity.* → module.cognito.* and module.irsa.*
# so existing state is preserved without requiring terraform state mv.
# Remove these blocks once you have run terraform apply successfully.
# ---------------------------------------------------------------------------

moved {
  from = module.identity.aws_cognito_user_pool.this
  to   = module.cognito.aws_cognito_user_pool.this
}

moved {
  from = module.identity.aws_cognito_user_pool_client.web
  to   = module.cognito.aws_cognito_user_pool_client.web
}

moved {
  from = module.identity.aws_cognito_user_group.roles
  to   = module.cognito.aws_cognito_user_group.roles
}

moved {
  from = module.identity.aws_iam_role.eso
  to   = module.irsa.aws_iam_role.eso
}

moved {
  from = module.identity.aws_iam_role_policy.eso
  to   = module.irsa.aws_iam_role_policy.eso
}

moved {
  from = module.identity.module.report_service_irsa
  to   = module.irsa.module.report_service_irsa
}

moved {
  from = module.identity.aws_iam_policy.report_service
  to   = module.irsa.aws_iam_policy.report_service
}

moved {
  from = module.identity.aws_iam_role_policy_attachment.report_service
  to   = module.irsa.aws_iam_role_policy_attachment.report_service
}

moved {
  from = module.identity.module.notification_service_irsa
  to   = module.irsa.module.notification_service_irsa
}

moved {
  from = module.identity.aws_iam_policy.notification_service
  to   = module.irsa.aws_iam_policy.notification_service
}

moved {
  from = module.identity.aws_iam_role_policy_attachment.notification_service
  to   = module.irsa.aws_iam_role_policy_attachment.notification_service
}

moved {
  from = module.identity.module.ai_lambda_irsa
  to   = module.irsa.module.ai_lambda_irsa
}

moved {
  from = module.identity.aws_iam_policy.ai_lambda
  to   = module.irsa.aws_iam_policy.ai_lambda
}

moved {
  from = module.identity.aws_iam_role_policy_attachment.ai_lambda
  to   = module.irsa.aws_iam_role_policy_attachment.ai_lambda
}

moved {
  from = module.storage.module.ai_lambda
  to   = module.lambda.module.ai_lambda
}

moved {
  from = module.storage.aws_lambda_permission.allow_s3
  to   = module.lambda.aws_lambda_permission.allow_s3
}

moved {
  from = module.storage.aws_s3_bucket_notification.reports
  to   = module.lambda.aws_s3_bucket_notification.reports
}
