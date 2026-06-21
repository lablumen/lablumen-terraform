terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
  }

  # ── REMOTE BACKEND (disabled — org account cleanup risk) ─────────────────────
  # The org AWS account periodically wipes resources. If the S3 bucket below is
  # deleted mid-session, the remote tfstate is gone and `terraform destroy`
  # becomes impossible, leaving orphaned resources with no state to track them.
  #
  # STATE IS LOCAL until the infra is stable and the account is confirmed safe.
  # To re-enable: uncomment the block, run `terraform init -migrate-state`, and
  # first apply bootstrap/ to (re-)create the bucket + DynamoDB table.
  # See CURRENT_STATUS.md § "State backend" for the full decision record.
  #
  # backend "s3" {
  #   bucket         = "lablumen-tfstate"
  #   key            = "global/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "lablumen-tflock"
  #   encrypt        = true
  # }
}
