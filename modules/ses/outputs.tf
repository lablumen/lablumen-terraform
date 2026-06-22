output "identity_arn" {
  description = "SES domain identity ARN. Used to scope ses:SendEmail in the notification IAM policy."
  value       = aws_sesv2_email_identity.sender.arn
}

output "domain" {
  description = "The verified SES domain identity."
  value       = aws_sesv2_email_identity.sender.email_identity
}
