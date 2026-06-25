variable "reports_bucket_name" {
  type        = string
  description = "Globally-unique S3 bucket name for patient report PDFs."
}

variable "sam_artifacts_bucket_name" {
  type        = string
  description = "Globally-unique S3 bucket name for SAM deployment artifacts (lablumen-ai-service zip)."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
