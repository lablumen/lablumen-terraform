variable "project" {
  type        = string
  description = "Project name prefix used for all IAM resource names."
}

# ---- GitHub OIDC / pipeline roles ----
variable "github_org" {
  type        = string
  description = "GitHub organization (or user) that owns the repositories."
}

variable "terraform_repo" {
  type        = string
  description = "Name of the Terraform repo (for the tf-plan/tf-apply trust policies)."
  default     = "lablumen-terraform"
}

variable "app_service_repos" {
  type        = list(string)
  description = "Backend service repos allowed to assume the app-ci-ecr role (push images)."
  default = [
    "lablumen-appointment-service",
    "lablumen-report-service",
    "lablumen-notification-service",
  ]
}

variable "frontend_repo" {
  type        = string
  description = "Frontend repo allowed to assume the frontend-deploy role."
  default     = "lablumen-frontend"
}

variable "ai_lambda_repo" {
  type        = string
  description = "AI service repo allowed to assume the ai-lambda-deploy role (SAM CI deploys)."
  default     = "lablumen-ai-service"
}


variable "state_bucket_name" {
  type        = string
  description = "S3 bucket holding Terraform state (granted to the tf-plan role; S3-native locking)."
}

variable "backend_ecr_repository_arns" {
  type        = list(string)
  description = "ECR repository ARNs for backend services (appointment/report/notification). Scopes the app_ci_ecr push policy."
}

variable "frontend_ecr_repository_arn" {
  type        = string
  description = "ECR repository ARN for lablumen/frontend exclusively. Scopes the frontend_build push policy."
}

# ---- EKS / IRSA ----
variable "oidc_provider_arn" {
  type        = string
  description = "EKS OIDC provider ARN — federated principal for all IRSA trust policies."
}

variable "cluster_oidc_issuer_url" {
  type        = string
  description = "Full HTTPS OIDC issuer URL of the EKS cluster."
}

variable "eso_service_account_name" {
  type        = string
  description = "Name of the ESO ServiceAccount in the external-secrets namespace."
  default     = "lablumen-eso"
}

variable "reports_bucket_arn" {
  type        = string
  description = "Reports S3 bucket ARN (report-service + ai-lambda scope)."
}

variable "queue_arn" {
  type        = string
  description = "SQS notifications queue ARN (notification-service scope)."
}

variable "ses_identity_arn" {
  type        = string
  description = "SES domain identity ARN (notification-service ses:SendEmail scope)."
}

variable "route53_zone_arn" {
  type        = string
  description = "Hosted zone ARN external-dns may change records in."
}

variable "sam_artifacts_bucket_arn" {
  type        = string
  description = "SAM artifacts bucket ARN. Scoped in the ai-lambda-deploy policy (s3:PutObject/GetObject)."
}

variable "kms_key_arn" {
  type        = string
  description = "Shared KMS key ARN for ECR and Secrets Manager access."
}

variable "bedrock_cross_account_role_arn" {
  type        = string
  description = "ARN of the cross-account IAM role (in the Bedrock-enabled account) that ai-lambda-exec assumes to invoke Bedrock models."
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
