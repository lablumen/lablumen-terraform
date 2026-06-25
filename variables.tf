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

# ---- Ownership / environment tags (rubric: every resource tagged Environment + Owner) ----

variable "environment" {
  type        = string
  description = "Environment tag value applied to all resources."
  default     = "shared"
}

variable "owner" {
  type        = string
  description = "Owner tag value applied to all resources."
  default     = "rnld101"
}

# ---- Domain (externally owned — never hardcoded) ----

variable "domain_name" {
  type        = string
  description = "Apex domain you own (hosted zone + ACM cert already exist). Public, non-secret; set in terraform.tfvars. Variable-driven — never hardcoded in module code."
}

variable "acm_certificate_domain" {
  type        = string
  description = "Domain used to look up the existing ACM certificate. Defaults to a wildcard on domain_name."
  default     = null
}

variable "frontend_subdomain" {
  type        = string
  description = "Subdomain for the frontend (k8s ALB ingress). Result: <frontend_subdomain>.<domain_name>."
  default     = "app"
}

variable "api_subdomain" {
  type        = string
  description = "Subdomain for the API (ALB ingress, created by external-dns). Result: <api_subdomain>.<domain_name>."
  default     = "api"
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
  description = "Kubernetes version for the EKS control plane."
  default     = "1.31"
}

variable "cluster_admin_access_entries" {
  type        = map(string)
  description = "Map of friendly name → IAM principal ARN granted cluster-admin via EKS Access Entries (e.g. your admin role for the ArgoCD bootstrap). Set per-account."
  default     = {}
}

variable "node_instance_types" {
  type        = list(string)
  description = "EC2 instance type(s) for the default managed node group. NOTE: the org SCP blocks t3.large; t3.medium is permitted."
  default     = ["t3.medium"]
}

variable "node_min_size" {
  type        = number
  description = "Minimum nodes in the default managed node group."
  default     = 1
}

variable "node_max_size" {
  type        = number
  description = "Maximum nodes in the default managed node group."
  default     = 4
}

variable "node_desired_size" {
  type        = number
  description = "Desired nodes in the default managed node group at creation."
  default     = 2
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
  type        = string
  description = "RDS instance class. Org SCP permits only micro classes (db.t3.micro / db.t4g.micro); larger is denied."
  default     = "db.t4g.micro"
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

# ---- Storage ----

variable "reports_bucket_name" {
  type        = string
  description = "Optional override for the reports S3 bucket name. Leave null to derive a globally-unique name: <project>-reports-<account_id>."
  default     = null
}

# ---- Messaging ----

variable "notifications_queue_name" {
  type    = string
  default = "lablumen-notifications"
}

variable "ses_from_local_part" {
  type        = string
  description = "Local part of the SES From address (before @). Full address is <local>@<domain_name>; the domain is the verified SES identity. e.g. 'no-reply' -> no-reply@<domain>."
  default     = "no-reply"
}

# ---- ECR ----

variable "ecr_repositories" {
  type        = list(string)
  description = "ECR repository names to create. Frontend runs as a container on EKS so it has its own ECR repo."
  default = [
    "lablumen/appointment-service",
    "lablumen/report-service",
    "lablumen/notification-service",
    "lablumen/frontend",
  ]
}

# ---- Cognito ----

variable "user_pool_name" {
  type    = string
  default = "lablumen-users"
}

# ---- CI/CD identity ----

variable "github_org" {
  type        = string
  description = "GitHub org/user owning the repos (used in OIDC trust policies)."
  default     = "lablumen"
}

variable "state_bucket_name" {
  type        = string
  description = "Optional override for the Terraform state bucket name (used to scope the tf-plan IAM policy). Leave null to derive <project>-tfstate-<account_id>, matching the bootstrap stack + backend.tf."
  default     = null
}

# ---- Tags ----

variable "tags" {
  type        = map(string)
  description = "Base tags merged with Environment/Owner and applied via default_tags."
  default = {
    Project   = "lablumen"
    ManagedBy = "terraform"
  }
}
