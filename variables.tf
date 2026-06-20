variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "lablumen"
}

# ---- Network ----
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

# ---- EKS ----
variable "cluster_version" {
  type    = string
  default = "1.31"
}

# ---- RDS Postgres ----
variable "db_engine_version" {
  type    = string
  default = "16.4"
}

variable "db_family" {
  type    = string
  default = "postgres16"
}

variable "db_major_engine_version" {
  type    = string
  default = "16"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_name" {
  type    = string
  default = "lablumen"
}

variable "db_username" {
  type    = string
  default = "lablumen"
}

# ---- Storage / Lambda ----
variable "reports_bucket_name" {
  type        = string
  description = "Globally-unique S3 bucket name for patient report PDFs."
  default     = "lablumen-reports-change-me"
}

variable "lambda_function_name" {
  type    = string
  default = "lablumen-ai-processing"
}

# ---- Messaging ----
variable "notifications_queue_name" {
  type    = string
  default = "lablumen-notifications"
}

variable "ses_sender_email" {
  type    = string
  default = "no-reply@lablumen.example"
}

# ---- Identity ----
variable "user_pool_name" {
  type    = string
  default = "lablumen-users"
}

variable "tags" {
  type = map(string)
  default = {
    Project   = "lablumen"
    ManagedBy = "terraform"
  }
}
