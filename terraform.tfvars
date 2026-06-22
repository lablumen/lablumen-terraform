# Centralized, non-secret configuration. (terraform.tfvars IS committed; *.auto.tfvars is gitignored.)
# Secrets (DB master password, etc.) are managed by AWS Secrets Manager (RDS-managed) and Cognito.
#
# DO NOT put the domain here — it must not be hardcoded in the repo. Provide it at apply time via:
#   export TF_VAR_domain_name="your-domain.tld"
# or an untracked file, e.g. secrets.auto.tfvars (gitignored):
#   domain_name                  = "your-domain.tld"
#   cluster_admin_access_entries = { me = "arn:aws:iam::<acct>:role/<your-admin-role>" }

aws_region  = "us-east-1"
project     = "lablumen"
environment = "shared"
owner       = "rnld101"
github_org  = "lablumen"

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

# Globally-unique bucket names — CHANGE before first apply.
reports_bucket_name  = "lablumen-reports-change-me"
frontend_bucket_name = "lablumen-frontend-change-me"

notifications_queue_name = "lablumen-notifications"
ses_sender_email         = "no-reply@lablumen.example"
user_pool_name           = "lablumen-users"

# Frontend is static-hosted via S3 + CloudFront — it is NOT an ECR repo.
ecr_repositories = [
  "lablumen/appointment-service",
  "lablumen/report-service",
  "lablumen/notification-service",
]
