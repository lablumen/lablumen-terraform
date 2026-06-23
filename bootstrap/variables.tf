variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type        = string
  description = "Project name — prefix for the derived state bucket name. Keep in sync with the root config."
  default     = "lablumen"
}

variable "state_bucket_name" {
  type        = string
  description = "Optional override for the state bucket name. Leave null to derive <project>-tfstate-<account_id>. Whatever this resolves to is what you put in ../backend.hcl."
  default     = null
}
