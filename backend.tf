# Remote state in S3 with native S3 locking (use_lockfile — TF 1.10+; DynamoDB is deprecated).
#
# CHICKEN-AND-EGG: the bucket must exist BEFORE `terraform init` can use this backend.
# Create it once via the bootstrap/ stack (it derives & outputs the name), then `terraform init`.
#
# The bucket name is a LITERAL here (Terraform evaluates the backend block before variables/locals).
# Convention: <project>-tfstate-<account_id>. On a new account, update this one line to match the
# name the bootstrap stack created (`terraform output -raw state_bucket`).
terraform {
  backend "s3" {
    bucket       = "lablumen-tfstate-261523981519"
    key          = "global/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
