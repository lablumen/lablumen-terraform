variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "state_bucket_name" {
  type        = string
  description = "S3 bucket holding the ROOT config's Terraform state. MUST match the bucket in ../backend.tf. S3 bucket names are globally unique — suffix with the account id if taken."
  default     = "lablumen-tfstate"
}
