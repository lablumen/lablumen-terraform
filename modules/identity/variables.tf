variable "project" { type = string }
variable "user_pool_name" { type = string }

variable "oidc_provider_arn" {
  type        = string
  description = "OIDC provider ARN for the EKS cluster. Used as the federated principal in all IRSA trust policies."
}

variable "cluster_oidc_issuer_url" {
  type        = string
  description = "Full HTTPS OIDC issuer URL (e.g. https://oidc.eks.us-east-1.amazonaws.com/id/XXX). Used to scope the ESO IRSA trust condition."
}

variable "reports_bucket_arn" {
  type        = string
  description = "S3 bucket ARN for report PDFs. Grants report-service and ai-lambda read/write access."
}

variable "queue_arn" {
  type        = string
  description = "SQS queue ARN for the notification-service IRSA policy."
}

variable "ses_sender_email" {
  type        = string
  description = "Verified SES sender identity (email address) for the notification-service IRSA policy."
}

variable "tags" { type = map(string) }
