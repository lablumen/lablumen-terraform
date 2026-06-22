variable "domain_name" {
  type        = string
  description = "Domain to register as a verified SES sending identity (Easy DKIM via Route53)."
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 hosted zone ID for the domain, where the DKIM CNAME records are created."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
}
