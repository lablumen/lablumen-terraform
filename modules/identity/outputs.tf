output "user_pool_id" {
  value = aws_cognito_user_pool.this.id
}

output "app_client_id" {
  value = aws_cognito_user_pool_client.web.id
}

output "report_service_role_arn" {
  description = "IRSA role ARN for report-service (S3 + Bedrock)."
  value       = module.report_service_irsa.iam_role_arn
}

output "eso_irsa_role_arn" {
  description = "IRSA role ARN for External Secrets Operator. Annotate the ESO ServiceAccount with this value."
  value       = aws_iam_role.eso.arn
}

output "notification_service_role_arn" {
  description = "IRSA role ARN for notification-service (SQS + SES)."
  value       = module.notification_service_irsa.iam_role_arn
}

output "ai_lambda_role_arn" {
  description = "IRSA role ARN for ai-lambda (Textract + Bedrock + S3)."
  value       = module.ai_lambda_irsa.iam_role_arn
}
