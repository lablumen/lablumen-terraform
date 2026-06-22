output "reports_bucket_id" {
  description = "Reports bucket name. Used by modules/lambda for the S3 event notification and SSM config."
  value       = module.reports_bucket.s3_bucket_id
}

output "reports_bucket_arn" {
  description = "Reports bucket ARN. Used by modules/iam to scope report-service and ai-lambda policies."
  value       = module.reports_bucket.s3_bucket_arn
}

output "frontend_bucket_id" {
  description = "Frontend SPA bucket name."
  value       = module.frontend_bucket.s3_bucket_id
}

output "frontend_bucket_arn" {
  description = "Frontend SPA bucket ARN. Used to scope the frontend-deploy role + CloudFront OAC policy."
  value       = module.frontend_bucket.s3_bucket_arn
}

output "frontend_bucket_regional_domain_name" {
  description = "Frontend bucket regional domain name — the CloudFront S3 origin."
  value       = module.frontend_bucket.s3_bucket_bucket_regional_domain_name
}
