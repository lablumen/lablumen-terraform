# Remote state in S3 with native S3 locking (use_lockfile — TF 1.10+; DynamoDB is deprecated).
#
# CHICKEN-AND-EGG: the bucket must exist BEFORE `terraform init` can use this backend.
# Create it once via the bootstrap/ stack (see bootstrap/README.md), then `terraform init -migrate-state`.
#
# Values are hardcoded here (not variables) because Terraform evaluates the backend block before
# variables are available. Keep the bucket name in sync with the bootstrap/ stack.
terraform {
  backend "s3" {
    bucket       = "lablumen-tfstate"
    key          = "global/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
