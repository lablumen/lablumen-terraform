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

  name            = var.project
  cidr            = var.vpc_cidr
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  cluster_name    = local.cluster_name
  tags            = var.tags
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

module "identity" {
  source = "./modules/identity"

  project            = var.project
  user_pool_name     = var.user_pool_name
  oidc_provider_arn  = module.eks.oidc_provider_arn
  reports_bucket_arn = module.storage.reports_bucket_arn
  tags               = var.tags
}
