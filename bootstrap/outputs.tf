output "state_bucket" {
  description = "S3 state bucket name. Put this in ../backend.hcl as `bucket`, then run `terraform init -backend-config=backend.hcl` in the root."
  value       = aws_s3_bucket.tfstate.id
}

output "backend_hcl" {
  description = "Ready-to-paste contents for ../backend.hcl."
  value       = <<-EOT
    bucket       = "${aws_s3_bucket.tfstate.id}"
    key          = "global/terraform.tfstate"
    region       = "${var.aws_region}"
    use_lockfile = true
    encrypt      = true
  EOT
}
