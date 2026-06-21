variable "reports_bucket_name" {
  type        = string
  description = "Globally-unique S3 bucket name for patient report PDFs. Must be set to a unique value before apply."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
