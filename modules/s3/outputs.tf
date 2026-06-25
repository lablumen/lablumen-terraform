output "reports_bucket_id" {
  description = "Reports bucket name. Used by SSM config and IAM policy scoping."
  value       = module.reports_bucket.s3_bucket_id
}

output "reports_bucket_arn" {
  description = "Reports bucket ARN. Used by modules/iam to scope report-service and ai-lambda policies."
  value       = module.reports_bucket.s3_bucket_arn
}

output "sam_artifacts_bucket_name" {
  description = "SAM artifacts bucket name. Passed to `sam deploy --s3-bucket` in lablumen-ai-service CI."
  value       = module.sam_artifacts_bucket.s3_bucket_id
}

output "sam_artifacts_bucket_arn" {
  description = "SAM artifacts bucket ARN. Scoped in the ai-lambda-deploy IAM policy (s3:PutObject)."
  value       = module.sam_artifacts_bucket.s3_bucket_arn
}

