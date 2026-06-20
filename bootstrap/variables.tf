variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "state_bucket_name" {
  type        = string
  description = "S3 bucket holding the ROOT config's Terraform state. MUST match the backend block in ../versions.tf. S3 bucket names are globally unique — suffix with the account id if taken."
  default     = "lablumen-tfstate"
}

variable "lock_table_name" {
  type        = string
  description = "DynamoDB table for Terraform state locking. MUST match the backend block in ../versions.tf."
  default     = "lablumen-tflock"
}
