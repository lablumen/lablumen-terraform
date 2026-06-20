provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

locals {
  cluster_name = "${var.project}-eks"
}

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

module "eks" {
  source = "./modules/eks"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.network.vpc_id
  subnet_ids      = module.network.private_subnets
  tags            = var.tags
}

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
  subnet_ids           = module.network.private_subnets
  tags                 = var.tags
}

module "storage" {
  source = "./modules/storage"

  reports_bucket_name  = var.reports_bucket_name
  lambda_function_name = var.lambda_function_name
  lambda_source_path   = "${path.module}/../serverless/ai-processing-pipeline"
  tags                 = var.tags
}

module "messaging" {
  source = "./modules/messaging"

  queue_name       = var.notifications_queue_name
  ses_sender_email = var.ses_sender_email
  tags             = var.tags
}

module "ecr" {
  source = "./modules/ecr"

  repositories = [
    "lablumen/appointment-service",
    "lablumen/report-service",
    "lablumen/notification-service",
    "lablumen/frontend",
  ]

  tags = var.tags
}

module "identity" {
  source = "./modules/identity"

  project                 = var.project
  user_pool_name          = var.user_pool_name
  oidc_provider_arn       = module.eks.oidc_provider_arn
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  reports_bucket_arn      = module.storage.reports_bucket_arn
  queue_arn               = module.messaging.queue_arn
  ses_sender_email        = var.ses_sender_email
  tags                    = var.tags
}

module "secrets" {
  source = "./modules/secrets"

  runtime_secrets = {
    "lablumen/app/database-url" = "Full Postgres DSN incl. creds for service pods + ai_lambda. Compose from module.data endpoint + the RDS-managed master secret."
  }

  ssm_config = {
    "reports-bucket"        = module.storage.reports_bucket_id
    "sqs-url"               = module.messaging.queue_url
    "cognito-user-pool-id"  = module.identity.user_pool_id
    "cognito-app-client-id" = module.identity.app_client_id
    "ses-sender"            = var.ses_sender_email
    "bedrock-embed-model"   = "amazon.titan-embed-text-v1"
    "bedrock-text-model"    = "amazon.nova-lite-v1:0"
    "region"                = var.aws_region
    "presigned-url-ttl"     = "3600"
    "cors-origins"          = "http://localhost:5173"
  }

  tags = var.tags
}
