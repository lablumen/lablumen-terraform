output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  value = module.data.db_endpoint
}

output "rds_master_user_secret_arn" {
  description = "Secrets Manager ARN holding the RDS master credentials (RDS-managed, not Terraform-managed)."
  value       = module.data.master_user_secret_arn
}

output "reports_bucket" {
  value = module.storage.reports_bucket_id
}

output "notifications_queue_url" {
  value = module.messaging.queue_url
}

output "cognito_user_pool_id" {
  value = module.identity.user_pool_id
}

output "cognito_app_client_id" {
  value = module.identity.app_client_id
}

# ---- Phase 0 handshake outputs (non-secret pointers) ----

output "ecr_repository_urls" {
  description = "ECR repo URIs. NON-SECRET — consumed as Helm image.repository in lablumen-k8s."
  value       = module.ecr.repository_urls
}

output "runtime_secret_arns" {
  description = "Secrets Manager namespace ARNs. Values are hand-populated; ESO references them by name."
  value       = module.secrets.secret_arns
}

output "ssm_param_names" {
  description = "Full SSM parameter paths published under /lablumen/config/. Referenced in ESO ExternalSecret manifests."
  value       = module.secrets.ssm_param_names
}

output "eso_irsa_role_arn" {
  description = "IRSA role ARN for External Secrets Operator. Annotate the ESO ServiceAccount with this value in lablumen-k8s."
  value       = module.identity.eso_irsa_role_arn
}

output "notification_service_role_arn" {
  description = "IRSA role ARN for notification-service (SQS + SES)."
  value       = module.identity.notification_service_role_arn
}

output "ai_lambda_role_arn" {
  description = "IRSA role ARN for ai-lambda (Textract + Bedrock + S3)."
  value       = module.identity.ai_lambda_role_arn
}
