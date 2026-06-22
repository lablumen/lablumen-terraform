provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Authenticates to the EKS cluster using a short-lived token from the AWS CLI (no kubeconfig file,
# no static credentials). Used by kubernetes.tf to create namespaces + IRSA ServiceAccounts.
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}
