variable "identifier" {
  type        = string
  description = "RDS instance identifier (must be unique within the AWS account/region)."
}

variable "engine_version" {
  type        = string
  description = "PostgreSQL engine version string (e.g. '16.4')."
}

variable "family" {
  type        = string
  description = "DB parameter group family (e.g. 'postgres16'). Must match the major engine version."
}

variable "major_engine_version" {
  type        = string
  description = "Major engine version string used for the option group (e.g. '16')."
}

variable "instance_class" {
  type        = string
  description = "RDS instance class (e.g. 'db.t3.medium'). Determines compute and memory."
}

variable "allocated_storage" {
  type        = number
  description = "Initial allocated storage size in GiB."
}

variable "db_name" {
  type        = string
  description = "Name of the default database created when the instance is provisioned."
}

variable "username" {
  type        = string
  description = "Master DB username. Credentials are managed by Secrets Manager — no password is stored in state."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the RDS security group is created."
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block. Used to scope the RDS security group ingress rule to the entire VPC."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the RDS DB subnet group. Should be the isolated DB-tier subnets."
}

variable "deletion_protection" {
  type        = bool
  description = "Enable RDS deletion protection. Set to true for production environments."
  default     = false
}

variable "skip_final_snapshot" {
  type        = bool
  description = "If false, a final DB snapshot is taken before deletion."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
