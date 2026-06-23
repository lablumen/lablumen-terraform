output "state_bucket" {
  description = "S3 state bucket name. Put this literal in ../backend.tf as `bucket`, then run `terraform init` in the root."
  value       = aws_s3_bucket.tfstate.id
}
