output "secret_arns" {
  description = "Map of secret name → ARN. ESO references secrets by name; ARNs are for IAM policy scoping."
  value       = { for k, s in aws_secretsmanager_secret.runtime : k => s.arn }
}

output "secret_names" {
  description = "List of created Secrets Manager secret names."
  value       = keys(aws_secretsmanager_secret.runtime)
}
