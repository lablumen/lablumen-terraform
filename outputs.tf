output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  description = "RDS Postgres connection endpoint (host:port)."
  value       = module.data.db_endpoint
}

output "rds_master_user_secret_arn" {
  description = "Secrets Manager ARN holding the RDS master credentials (RDS-managed, not Terraform-managed)."
  value       = module.data.master_user_secret_arn
}

output "reports_bucket" {
  description = "S3 bucket name for report PDFs."
  value       = module.storage.reports_bucket_id
}

output "notifications_queue_url" {
  description = "SQS queue URL consumed by notification-service."
  value       = module.messaging.queue_url
}

output "cognito_user_pool_id" {
  description = "Cognito user pool ID. Stored in SSM under /lablumen/config/cognito-user-pool-id."
  value       = module.cognito.user_pool_id
}

output "cognito_app_client_id" {
  description = "Cognito web app client ID. Stored in SSM under /lablumen/config/cognito-app-client-id."
  value       = module.cognito.app_client_id
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
  value       = module.irsa.eso_irsa_role_arn
}

output "report_service_role_arn" {
  description = "IRSA role ARN for report-service (S3 + Bedrock). Annotate the report-service ServiceAccount."
  value       = module.irsa.report_service_role_arn
}

output "notification_service_role_arn" {
  description = "IRSA role ARN for notification-service (SQS + SES)."
  value       = module.irsa.notification_service_role_arn
}

output "ai_lambda_role_arn" {
  description = "IRSA role ARN for ai-lambda (Textract + Bedrock + S3)."
  value       = module.irsa.ai_lambda_role_arn
}

output "lbc_irsa_role_arn" {
  description = "IRSA role ARN for the AWS Load Balancer Controller. Annotate the lbc ServiceAccount in lablumen-k8s."
  value       = module.irsa.lbc_irsa_role_arn
}

output "karpenter_controller_role_arn" {
  description = "IRSA role ARN for the Karpenter controller. Annotate the Karpenter ServiceAccount in lablumen-k8s."
  value       = module.eks.karpenter_controller_role_arn
}

output "karpenter_queue_name" {
  description = "SQS queue name for Karpenter spot-interruption handling. Set in karpenter.yaml settings.interruptionQueue."
  value       = module.eks.karpenter_queue_name
}
