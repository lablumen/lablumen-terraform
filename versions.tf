terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # Remote state backend (Phase 0). The bucket + lock table below are created ONCE by ./bootstrap
  # (which uses local state — it cannot store its own state in the backend it creates). After
  # `terraform apply` in ./bootstrap, run `terraform init -migrate-state` here to move root state
  # into S3. The bucket/table names here are literals (backend blocks cannot use variables) and
  # MUST match ./bootstrap/variables.tf.
  backend "s3" {
    bucket         = "lablumen-tfstate"
    key            = "global/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "lablumen-tflock"
    encrypt        = true
  }
}
