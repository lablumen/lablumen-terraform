output "ses_sender_identity" {
  value = aws_sesv2_email_identity.sender.email_identity
}

output "ses_sender_identity_arn" {
  value = aws_sesv2_email_identity.sender.arn
}
