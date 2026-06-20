terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # NO backend block. This config bootstraps the remote-state backend itself, so it must use
  # LOCAL state — you cannot store the backend's own state inside the backend it creates.
}
