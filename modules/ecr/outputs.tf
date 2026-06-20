output "repository_urls" {
  description = "Map of repository name → URI. NON-SECRET — consumed as Helm image.repository in lablumen-k8s."
  value       = { for k, r in aws_ecr_repository.this : k => r.repository_url }
}
