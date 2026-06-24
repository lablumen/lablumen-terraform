output "reports_bucket_id" {
  description = "Reports bucket name. Used by modules/lambda for the S3 event notification and SSM config."
  value       = module.reports_bucket.s3_bucket_id
}

output "reports_bucket_arn" {
  description = "Reports bucket ARN. Used by modules/iam to scope report-service and ai-lambda policies."
  value       = module.reports_bucket.s3_bucket_arn
}
