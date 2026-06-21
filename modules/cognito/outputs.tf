output "user_pool_id" {
  description = "Cognito user pool ID. Stored in SSM and referenced by ESO + application config."
  value       = aws_cognito_user_pool.this.id
}

output "app_client_id" {
  description = "Web app client ID. Stored in SSM and used by the frontend for SRP authentication."
  value       = aws_cognito_user_pool_client.web.id
}
