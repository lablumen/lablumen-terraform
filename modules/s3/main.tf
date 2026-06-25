# Private PHI store — KMS-encrypted, versioned, no public access.
# Lambda trigger wiring lives in modules/lambda to keep storage and compute concerns separate.
module "reports_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1"

  bucket        = var.reports_bucket_name
  force_destroy = true

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "aws:kms"
      }
    }
  }

  tags = var.tags
}

# SAM deployment artifacts — private, no KMS (deployment zips are not sensitive).
# Used by `sam deploy --s3-bucket` in the lablumen-ai-service CI pipeline.
module "sam_artifacts_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1"

  bucket        = var.sam_artifacts_bucket_name
  force_destroy = true

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = false
  }

  tags = var.tags
}

resource "aws_s3_bucket_notification" "reports" {
  bucket      = module.reports_bucket.s3_bucket_id
  eventbridge = true
}

