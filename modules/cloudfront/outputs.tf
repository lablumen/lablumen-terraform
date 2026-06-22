output "distribution_id" {
  description = "CloudFront distribution ID (for the frontend-deploy invalidation permission)."
  value       = aws_cloudfront_distribution.frontend.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN."
  value       = aws_cloudfront_distribution.frontend.arn
}

output "distribution_domain_name" {
  description = "CloudFront default domain name (e.g. dxxxx.cloudfront.net)."
  value       = aws_cloudfront_distribution.frontend.domain_name
}
