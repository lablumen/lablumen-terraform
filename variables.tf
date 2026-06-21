variable "aws_region" {
  type        = string
  description = "AWS region to deploy all resources into."
  default     = "us-east-1"
}

variable "project" {
  type        = string
  description = "Project name used as a prefix for all named resources."
  default     = "lablumen"
}

# ---- Network ----

variable "vpc_cidr" {
  type        = string
  description = "IPv4 CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones to span for subnets and endpoints."
  default     = ["us-east-1a", "us-east-1b"]
}

variable "private_subnets" {
  type        = list(string)
  description = "CIDR blocks for private (EKS worker / Lambda ENI) subnets, one per AZ."
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  type        = list(string)
  description = "CIDR blocks for public (NAT GW / internet ALB) subnets, one per AZ."
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "database_subnets" {
  type        = list(string)
  description = "CIDR blocks for isolated RDS DB-tier subnets (no NAT or IGW route), one per AZ."
  default     = ["10.0.201.0/24", "10.0.202.0/24"]
}

# ---- EKS ----

variable "cluster_version" {
  type        = string
  description = "Kubernetes version to run on the EKS control plane (e.g. '1.31')."
  default     = "1.31"
}

# ---- RDS Postgres ----

variable "db_engine_version" {
  type        = string
  description = "PostgreSQL engine version (e.g. '16.4')."
  default     = "16.4"
}

variable "db_family" {
  type        = string
  description = "DB parameter group family (e.g. 'postgres16')."
  default     = "postgres16"
}

variable "db_major_engine_version" {
  type        = string
  description = "Major engine version for the option group (e.g. '16')."
  default     = "16"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class (e.g. 'db.t3.medium')."
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  type        = number
  description = "Initial allocated storage in GiB."
  default     = 20
}

variable "db_name" {
  type        = string
  description = "Name of the default database created at provisioning time."
  default     = "lablumen"
}

variable "db_username" {
  type        = string
  description = "Master DB username. Credentials are managed by Secrets Manager."
  default     = "lablumen"
}

# ---- Storage / Lambda ----

variable "reports_bucket_name" {
  type        = string
  description = "Globally-unique S3 bucket name for patient report PDFs. Change this before apply."
  default     = "lablumen-reports-change-me"
}

variable "lambda_function_name" {
  type        = string
  description = "Name of the AI processing Lambda function."
  default     = "lablumen-ai-processing"
}

# ---- Messaging ----

variable "notifications_queue_name" {
  type        = string
  description = "SQS queue name for the notification-service."
  default     = "lablumen-notifications"
}

variable "ses_sender_email" {
  type        = string
  description = "Email address registered as a verified SES v2 sender identity."
  default     = "no-reply@lablumen.example"
}

# ---- ECR ----

variable "ecr_repositories" {
  type        = list(string)
  description = "List of ECR repository names to create. Add new service images here — no changes to main.tf required."
  default = [
    "lablumen/appointment-service",
    "lablumen/report-service",
    "lablumen/notification-service",
    "lablumen/frontend",
  ]
}

# ---- Identity ----

variable "user_pool_name" {
  type        = string
  description = "Display name for the Cognito user pool."
  default     = "lablumen-users"
}

# ---- Tags ----

variable "tags" {
  type        = map(string)
  description = "Default tags applied to all resources via the AWS provider default_tags block."
  default = {
    Project   = "lablumen"
    ManagedBy = "terraform"
  }
}
