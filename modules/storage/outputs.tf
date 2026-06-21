output "reports_bucket_id" {
  description = "S3 bucket ID (name). Used by modules/lambda for the S3 event notification and SSM config."
  value       = module.reports_bucket.s3_bucket_id
}

output "reports_bucket_arn" {
  description = "S3 bucket ARN. Used by modules/irsa to scope IAM policies for report-service and ai-lambda."
  value       = module.reports_bucket.s3_bucket_arn
}
