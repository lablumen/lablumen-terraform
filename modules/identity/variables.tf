variable "project" { type = string }
variable "user_pool_name" { type = string }
variable "oidc_provider_arn" { type = string }
variable "reports_bucket_arn" { type = string }
variable "tags" { type = map(string) }
