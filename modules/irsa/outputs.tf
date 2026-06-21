output "eso_irsa_role_arn" {
  description = "IRSA role ARN for External Secrets Operator. Annotate the ESO ServiceAccount with this value in lablumen-k8s."
  value       = aws_iam_role.eso.arn
}

output "report_service_role_arn" {
  description = "IRSA role ARN for report-service (S3 + Bedrock). Annotate the report-service ServiceAccount."
  value       = module.report_service_irsa.iam_role_arn
}

output "notification_service_role_arn" {
  description = "IRSA role ARN for notification-service (SQS + SES). Annotate the notification-service ServiceAccount."
  value       = module.notification_service_irsa.iam_role_arn
}

output "ai_lambda_role_arn" {
  description = "IRSA role ARN for ai-lambda (Textract + Bedrock + S3). Annotate the ai-lambda ServiceAccount."
  value       = module.ai_lambda_irsa.iam_role_arn
}

output "lbc_irsa_role_arn" {
  description = "IRSA role ARN for the AWS Load Balancer Controller. Annotate the lbc ServiceAccount in kube-system."
  value       = module.lbc_irsa.iam_role_arn
}
