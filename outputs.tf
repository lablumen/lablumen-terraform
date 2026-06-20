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
  description = "Secrets Manager ARN holding the RDS master credentials."
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
