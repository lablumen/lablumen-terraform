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

variable "app_repo" {
  type        = string
  description = "Name of the application repo (for the app-ci-ecr / frontend-deploy trust policies)."
  default     = "lablumen-app"
}

variable "state_bucket_name" {
  type        = string
  description = "S3 bucket holding Terraform state (granted to the tf-plan role; S3-native locking)."
}

variable "ecr_repository_arns" {
  type        = list(string)
  description = "ECR repository ARNs the app CI role may push to."
}

variable "frontend_bucket_arn" {
  type        = string
  description = "Frontend S3 bucket ARN (granted to the frontend-deploy role)."
}

variable "cloudfront_distribution_arn" {
  type        = string
  description = "CloudFront distribution ARN (frontend-deploy CreateInvalidation scope)."
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

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
