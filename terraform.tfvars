# Centralized, non-secret configuration. (terraform.tfvars IS committed; *.auto.tfvars is gitignored.)
# Secrets (DB master password, etc.) are managed by AWS Secrets Manager (RDS-managed) and Cognito.
# The domain below is a public, non-secret value (it's variable-driven, never baked into module code).
# Account-specific extras (e.g. cluster_admin_access_entries) can go in an untracked secrets.auto.tfvars.

aws_region  = "us-east-1"
project     = "lablumen"
environment = "shared"
owner       = "rnld101"
github_org  = "lablumen"

# Apex domain you own (hosted zone + ACM cert already exist). Used for SES, CloudFront, ingress hosts.
domain_name = "rnld101.xyz"

vpc_cidr         = "10.0.0.0/16"
azs              = ["us-east-1a", "us-east-1b"]
private_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets   = ["10.0.101.0/24", "10.0.102.0/24"]
database_subnets = ["10.0.201.0/24", "10.0.202.0/24"]

cluster_version = "1.31"

# Org SCP blocks t3.large — t3.medium is permitted.
node_instance_types = ["t3.medium"]
node_min_size       = 1
node_max_size       = 4
node_desired_size   = 2

db_engine_version = "16.4"
# Org SCP allows only micro RDS classes (db.t3.medium+ is denied). t4g.micro = Graviton, cheapest allowed.
db_instance_class = "db.t4g.micro"

# S3 bucket names (state / reports / frontend) are DERIVED as <project>-<purpose>-<account_id> for
# global uniqueness and account portability — see locals.tf. Override the *_bucket_name vars only if
# you need a specific name.

notifications_queue_name = "lablumen-notifications"
user_pool_name           = "lablumen-users"

# SES sends from <ses_from_local_part>@<domain_name>. The DOMAIN comes from domain_name (set via
# TF_VAR_domain_name / secrets.auto.tfvars) and is registered as a verified SES identity (Easy DKIM
# in Route53). You set only the local part here → result: no-reply@<your-domain>.
ses_from_local_part = "no-reply"

ecr_repositories = [
  "lablumen/appointment-service",
  "lablumen/report-service",
  "lablumen/notification-service",
  "lablumen/frontend",
]
