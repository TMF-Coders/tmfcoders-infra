terraform {
  required_version = ">= 1.10"

  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.48"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }

  # Bootstrap created the state bucket on local state, then migrated here:
  #   terraform init -migrate-state -backend-config=backend.hcl
  backend "s3" {}
}
