variable "config" {
  type        = map(string)
  description = "Map of parameter key suffix → resolved value. Published under path_prefix/<key> as plain String parameters."
  default     = {}
}

variable "path_prefix" {
  type        = string
  description = "SSM parameter path prefix (no trailing slash). ESO is granted ssm:GetParameter* on this prefix only."
  default     = "/lablumen/config"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
