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
  description = "EC2 instance type(s) for the default managed node group."
  default     = ["t3.large"]
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

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
