output "secret_arns" {
  description = "Map of secret name → ARN. ESO ClusterSecretStore references secrets by name; ARNs are for IAM policy scoping."
  value       = { for k, s in aws_secretsmanager_secret.runtime : k => s.arn }
}

output "ssm_param_names" {
  description = "Map of key suffix → full SSM parameter path. Reference in ESO ExternalSecret manifests."
  value       = { for k, p in aws_ssm_parameter.config : k => p.name }
}
