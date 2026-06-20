output "user_pool_id" {
  value = aws_cognito_user_pool.this.id
}

output "app_client_id" {
  value = aws_cognito_user_pool_client.web.id
}

output "report_service_role_arn" {
  value = module.report_service_irsa.iam_role_arn
}
