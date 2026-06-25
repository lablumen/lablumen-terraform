output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "karpenter_node_iam_role_name" {
  value = module.karpenter.node_iam_role_name
}

output "karpenter_queue_name" {
  value = module.karpenter.queue_name
}

output "karpenter_controller_role_arn" {
  value = module.karpenter.iam_role_arn
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "node_group_iam_role_name" {
  description = "IAM role name of the default EKS managed node group. Used to attach KMS Decrypt for KMS-encrypted ECR image pulls."
  value       = module.eks.eks_managed_node_groups["default"].iam_role_name
}

