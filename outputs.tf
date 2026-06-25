# ---- Cluster ----
output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = module.eks.cluster_endpoint
}

# ---- Data / messaging ----
output "rds_endpoint" {
  description = "RDS Postgres connection endpoint (host:port)."
  value       = module.rds.db_endpoint
}

output "rds_master_user_secret_arn" {
  description = "Secrets Manager ARN holding the RDS master credentials (RDS-managed)."
  value       = module.rds.master_user_secret_arn
}

output "database_url_template" {
  description = "Correct DSN to paste into lablumen/app/database-url (replace <PASSWORD> with the password from rds_master_user_secret_arn). The +asyncpg driver prefix and single :5432 port are required."
  value       = "postgresql+asyncpg://lablumen:<PASSWORD>@${module.rds.db_endpoint}/lablumen"
}

output "reports_bucket" {
  description = "S3 bucket name for report PDFs."
  value       = module.s3.reports_bucket_id
}

output "notifications_queue_url" {
  description = "SQS queue URL consumed by notification-service."
  value       = module.sqs.queue_url
}

output "cognito_user_pool_id" {
  value = module.cognito.user_pool_id
}

output "cognito_app_client_id" {
  value = module.cognito.app_client_id
}

# ---- Frontend / DNS ----
output "frontend_url" {
  description = "Public HTTPS URL of the frontend (served by nginx on EKS via ALB ingress)."
  value       = "https://${local.frontend_fqdn}"
}

output "api_fqdn" {
  description = "API hostname (external-dns creates the Route53 record from the ALB Ingress)."
  value       = local.api_fqdn
}

# ---- Phase-0 handshake (non-secret pointers consumed by lablumen-k8s) ----
output "image_registry" {
  description = "ECR registry base URL (<account_id>.dkr.ecr.<region>.amazonaws.com). Copy into lablumen-k8s global-values.yaml global.imageRegistry."
  value       = local.image_registry
}

output "ecr_repository_urls" {
  description = "ECR repo URIs. NON-SECRET — consumed as Helm image.repository."
  value       = module.ecr.repository_urls
}

output "runtime_secret_arns" {
  description = "Secrets Manager namespace ARNs. Values are hand-populated; ESO references by name."
  value       = module.secretsmanager.secret_arns
}

output "ssm_param_names" {
  description = "Full SSM parameter paths published under /lablumen/config/."
  value       = module.ssm.param_names
}

# ---- IRSA role ARNs (annotate the matching k8s ServiceAccounts) ----
output "eso_irsa_role_arn" {
  value = module.iam.eso_irsa_role_arn
}

output "report_service_role_arn" {
  value = module.iam.report_service_role_arn
}

output "notification_service_role_arn" {
  value = module.iam.notification_service_role_arn
}

output "lbc_irsa_role_arn" {
  value = module.iam.lbc_irsa_role_arn
}

output "external_dns_role_arn" {
  value = module.iam.external_dns_role_arn
}

output "ai_lambda_role_arn" {
  value = module.iam.ai_lambda_exec_role_arn
}

output "karpenter_controller_role_arn" {
  value = module.eks.karpenter_controller_role_arn
}

output "karpenter_queue_name" {
  description = "SQS queue name for Karpenter spot-interruption handling."
  value       = module.eks.karpenter_queue_name
}

# ---- Pipeline (GitHub Actions OIDC) role ARNs ----
output "tf_plan_role_arn" {
  value = module.iam.tf_plan_role_arn
}

output "tf_apply_role_arn" {
  value = module.iam.tf_apply_role_arn
}

output "app_ci_ecr_role_arn" {
  value = module.iam.app_ci_ecr_role_arn
}

output "frontend_build_role_arn" {
  description = "IAM role ARN assumed by the lablumen-frontend CI to push images to ECR."
  value       = module.iam.frontend_build_role_arn
}
