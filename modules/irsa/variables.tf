variable "project" {
  type        = string
  description = "Project name prefix used for all IAM resource names."
}

variable "oidc_provider_arn" {
  type        = string
  description = "OIDC provider ARN for the EKS cluster. Used as the federated principal in all IRSA trust policies."
}

variable "cluster_oidc_issuer_url" {
  type        = string
  description = "Full HTTPS OIDC issuer URL (e.g. https://oidc.eks.us-east-1.amazonaws.com/id/XXX). Used to scope the ESO IRSA trust condition to the exact service account."
}

variable "reports_bucket_arn" {
  type        = string
  description = "S3 bucket ARN for report PDFs. Grants report-service and ai-lambda s3:GetObject + s3:PutObject."
}

variable "queue_arn" {
  type        = string
  description = "SQS queue ARN. Grants notification-service send/receive/delete/get-attributes."
}

variable "ses_sender_email" {
  type        = string
  description = "Verified SES sender identity email. Scopes the SES IAM action to this identity only."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
