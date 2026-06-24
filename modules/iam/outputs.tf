# ---- Pipeline role ARNs (wire into GitHub Actions workflows) ----
output "tf_plan_role_arn" {
  value       = aws_iam_role.tf_plan.arn
  description = "Assume in the terraform PR/plan job."
}

output "tf_apply_role_arn" {
  value       = aws_iam_role.tf_apply.arn
  description = "Assume in the terraform apply job (GitHub Environment 'production')."
}

output "app_ci_ecr_role_arn" {
  value       = aws_iam_role.app_ci_ecr.arn
  description = "Assume in the app CI build/push job."
}

output "frontend_build_role_arn" {
  value       = aws_iam_role.frontend_build.arn
  description = "Assume in the frontend CI build/push job (lablumen-frontend repo, OIDC)."
}

output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}

# ---- IRSA role ARNs (annotate the matching k8s ServiceAccounts) ----
output "eso_irsa_role_arn" {
  value       = aws_iam_role.eso.arn
  description = "Annotate the ESO ServiceAccount (lablumen-eso)."
}

output "report_service_role_arn" {
  value       = module.report_service_irsa.iam_role_arn
  description = "Annotate report-service SAs (lablumen + lablumen-dev)."
}

output "notification_service_role_arn" {
  value       = module.notification_service_irsa.iam_role_arn
  description = "Annotate notification-service SAs (lablumen + lablumen-dev)."
}

output "lbc_irsa_role_arn" {
  value       = module.lbc_irsa.iam_role_arn
  description = "Annotate the aws-load-balancer-controller ServiceAccount."
}

output "external_dns_role_arn" {
  value       = module.external_dns_irsa.iam_role_arn
  description = "Annotate the external-dns ServiceAccount (kube-system)."
}

output "ai_lambda_role_arn" {
  value       = module.ai_lambda_irsa.iam_role_arn
  description = "IRSA role ARN for ai-lambda."
}
