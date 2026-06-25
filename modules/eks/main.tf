module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true

  # Access Entries (modern auth). The apply principal (tf-apply role) gets admin automatically;
  # additional human/role admins are granted via var.cluster_admin_access_entries.
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = false

  access_entries = {
    for name, arn in var.cluster_admin_access_entries : name => {
      principal_arn = arn
      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  # Control-plane logging to CloudWatch (lean observability — rubric "CloudWatch log groups").
  cluster_enabled_log_types              = var.cluster_enabled_log_types
  cloudwatch_log_group_retention_in_days = var.log_retention_days

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
    }
  }

  # Karpenter discovers the node security group via this tag.
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  tags = var.tags
}

# Karpenter supporting resources (IAM role, instance profile, interruption SQS queue).
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.24"

  cluster_name = module.eks.cluster_name

  # Deterministic name so ec2nodeclass.yaml never needs updating after a re-apply.
  # Format: KarpenterNodeRole-<cluster_name>
  node_iam_role_name            = "KarpenterNodeRole-${var.cluster_name}"
  node_iam_role_use_name_prefix = false

  # v1.0.x controller IAM permissions (matches the karpenter 1.0.6 chart deployed via ArgoCD).
  enable_v1_permissions = true

  # Use IRSA (OIDC) for the controller — consistent with every other addon (ESO, ALB, external-dns,
  # services). The submodule defaults to EKS Pod Identity, but this cluster has no pod-identity agent
  # or association, and the karpenter ServiceAccount is IRSA-annotated by kubernetes.tf.
  enable_pod_identity             = false
  create_pod_identity_association = false
  enable_irsa                     = true
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["kube-system:karpenter"]

  tags = var.tags
}
