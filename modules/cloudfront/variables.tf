variable "name" {
  type        = string
  description = "Name prefix for CloudFront resources (e.g. 'lablumen')."
}

variable "aliases" {
  type        = list(string)
  description = "Alternate domain names (CNAMEs) for the distribution, e.g. ['app.example.com']. Must be covered by the ACM cert."
}

variable "frontend_bucket_id" {
  type        = string
  description = "Frontend S3 bucket name (for the OAC bucket policy)."
}

variable "frontend_bucket_arn" {
  type        = string
  description = "Frontend S3 bucket ARN (for the OAC bucket policy)."
}

variable "frontend_bucket_regional_domain_name" {
  type        = string
  description = "Frontend S3 bucket regional domain name (the CloudFront origin)."
}

variable "acm_certificate_arn" {
  type        = string
  description = "ARN of the (externally-managed) ACM certificate in us-east-1 covering the aliases."
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 hosted zone ID in which to create the alias A records."
}

variable "price_class" {
  type        = string
  description = "CloudFront price class."
  default     = "PriceClass_100"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
