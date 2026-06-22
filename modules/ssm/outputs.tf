output "param_names" {
  description = "Map of key suffix → full SSM parameter path. Reference in ESO ExternalSecret manifests."
  value       = { for k, p in aws_ssm_parameter.config : k => p.name }
}
