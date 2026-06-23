provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "lablumen"
      ManagedBy = "terraform"
      Component = "tf-state-backend"
    }
  }
}

# The state bucket name is DERIVED from the account ID (globally unique + portable), matching the root
# locals.tf. An explicit var.state_bucket_name override wins if set.
data "aws_caller_identity" "current" {}

locals {
  state_bucket_name = coalesce(var.state_bucket_name, "${var.project}-tfstate-${data.aws_caller_identity.current.account_id}")
}

# ---- S3 bucket backing the root Terraform state ----

resource "aws_s3_bucket" "tfstate" {
  bucket = local.state_bucket_name

  # State is the source of truth for ALL infrastructure — guard against accidental deletion.
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Locking is S3-native (root backend uses `use_lockfile = true`) — no DynamoDB table required.
# The lock is a short-lived <key>.tflock object written/deleted in this bucket by Terraform.
