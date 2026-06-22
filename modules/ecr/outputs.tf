output "repository_urls" {
  description = "Map of repository name → URI. NON-SECRET — consumed as Helm image.repository in lablumen-k8s."
  value       = { for k, r in aws_ecr_repository.this : k => r.repository_url }
}

output "repository_arns" {
  description = "Map of repository name → ARN. Used to scope the app-ci-ecr push policy."
  value       = { for k, r in aws_ecr_repository.this : k => r.arn }
}
