output "reports_bucket_id" {
  value = module.reports_bucket.s3_bucket_id
}

output "reports_bucket_arn" {
  value = module.reports_bucket.s3_bucket_arn
}

output "lambda_function_arn" {
  value = module.ai_lambda.lambda_function_arn
}
