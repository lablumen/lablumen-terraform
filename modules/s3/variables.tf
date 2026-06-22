variable "reports_bucket_name" {
  type        = string
  description = "Globally-unique S3 bucket name for patient report PDFs."
}

variable "frontend_bucket_name" {
  type        = string
  description = "Globally-unique S3 bucket name for the frontend SPA static assets (served via CloudFront)."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
