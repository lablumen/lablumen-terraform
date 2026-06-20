variable "runtime_secrets" {
  type        = map(string)
  description = "Map of Secrets Manager secret name → description. Terraform creates empty containers only; values are hand-populated out-of-band. No aws_secretsmanager_secret_version is created here."
}

variable "ssm_config" {
  type        = map(string)
  description = "Map of SSM parameter key suffix → resolved value. Published under ssm_path_prefix/<key> as plain String parameters."
  default     = {}
}

variable "ssm_path_prefix" {
  type        = string
  description = "SSM parameter path prefix (no trailing slash). ESO is granted ssm:GetParameter* on this prefix only."
  default     = "/lablumen/config"
}

variable "secret_recovery_window_days" {
  type        = number
  default     = 7
  description = "Recovery window (days) before a deleted secret is permanently purged."
}

variable "tags" { type = map(string) }
