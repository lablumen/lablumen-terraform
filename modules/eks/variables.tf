variable "cluster_name" {
  type        = string
  description = "EKS cluster name. Used as both the cluster identifier and the Karpenter node security group discovery tag."
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version to run on the EKS control plane (e.g. '1.31')."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the EKS cluster and managed node groups are placed."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs used for EKS worker nodes. Should span multiple AZs for HA."
}

variable "node_instance_types" {
  type        = list(string)
  description = "EC2 instance type(s) for the default managed node group. Account restricts to free-tier-eligible types — use c7i-flex.large (4 GiB) or m7i-flex.large (8 GiB)."
  default     = ["t3.medium"]
}

variable "node_min_size" {
  type        = number
  description = "Minimum number of nodes in the default managed node group."
  default     = 1
}

variable "node_max_size" {
  type        = number
  description = "Maximum number of nodes in the default managed node group."
  default     = 4
}

variable "node_desired_size" {
  type        = number
  description = "Desired number of nodes in the default managed node group at creation time."
  default     = 2
}

variable "cluster_admin_access_entries" {
  type        = map(string)
  description = "Map of friendly name → IAM principal ARN to grant cluster-admin via EKS Access Entries (e.g. your admin role for the ArgoCD bootstrap)."
  default     = {}
}

variable "cluster_enabled_log_types" {
  type        = list(string)
  description = "EKS control-plane log types to ship to CloudWatch."
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  type        = number
  description = "Retention for the EKS control-plane CloudWatch log group."
  default     = 14
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
