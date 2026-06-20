# Centralized, non-secret configuration. Secrets (DB master password, etc.) are managed by
# AWS Secrets Manager (RDS-managed) and Cognito — not stored here.
aws_region = "us-east-1"
project    = "lablumen"

vpc_cidr        = "10.0.0.0/16"
azs             = ["us-east-1a", "us-east-1b"]
private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

cluster_version = "1.31"

db_engine_version = "16.4"
db_instance_class = "db.t3.medium"

# NOTE: set a globally-unique bucket name before apply.
reports_bucket_name = "lablumen-reports-change-me"

notifications_queue_name = "lablumen-notifications"
ses_sender_email         = "no-reply@lablumen.example"
user_pool_name           = "lablumen-users"
