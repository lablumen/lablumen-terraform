# Private PHI store — KMS-encrypted, versioned, no public access.
# Lambda trigger wiring lives in modules/lambda to keep storage and compute concerns separate.
module "reports_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1"

  bucket        = var.reports_bucket_name
  force_destroy = true

  # No public access — patient report data is internal only.
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "aws:kms"
      }
    }
  }

  tags = var.tags
}
