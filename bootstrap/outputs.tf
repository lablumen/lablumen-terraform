output "state_bucket" {
  description = "S3 bucket name — paste into the root ../versions.tf backend block."
  value       = aws_s3_bucket.tfstate.id
}

output "lock_table" {
  description = "DynamoDB lock table name — paste into the root ../versions.tf backend block."
  value       = aws_dynamodb_table.tflock.id
}
