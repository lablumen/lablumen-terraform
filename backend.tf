# Remote state in S3 with native S3 locking (use_lockfile — TF 1.10+; DynamoDB is deprecated).
#
# PARTIAL backend config (account-portable): the backend block is intentionally EMPTY here because
# Terraform evaluates it before variables/locals exist, so account-specific values (the bucket name)
# cannot be derived inline. Supply them at init from a per-account file:
#
#     terraform init -backend-config=backend.hcl
#
# Copy backend.hcl.example -> backend.hcl and fill in the account's state bucket (created by the
# bootstrap/ stack, named <project>-tfstate-<account_id>). backend.hcl is gitignored.
terraform {
  backend "s3" {}
}
