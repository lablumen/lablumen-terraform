variable "name" {
  type        = string
  description = "Base name prefix used for all VPC resource names (e.g. 'lablumen' → 'lablumen-vpc')."
}

variable "cidr" {
  type        = string
  description = "IPv4 CIDR block for the VPC (e.g. '10.0.0.0/16')."
}

variable "azs" {
  type        = list(string)
  description = "List of Availability Zone names to deploy into (e.g. ['us-east-1a', 'us-east-1b', 'us-east-1c'])."
}

variable "private_subnets" {
  type        = list(string)
  description = "CIDR blocks for private subnets (one per AZ). Hosts EKS worker nodes and Lambda ENIs."
}

variable "public_subnets" {
  type        = list(string)
  description = "CIDR blocks for public subnets (one per AZ). Hosts NAT gateways and internet-facing ALBs."
}

variable "database_subnets" {
  type        = list(string)
  description = "CIDR blocks for isolated RDS DB-tier subnets (no NAT/IGW route). One per AZ."
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name. Used for Karpenter subnet discovery tags on private subnets."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
