terraform {
  required_version = ">= 1.10"

  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.48"
    }
  }

  # Bootstrap runs on LOCAL state first (it creates the state bucket).
  # After the first apply, uncomment the block below and run:
  #   terraform init -migrate-state -backend-config=backend.hcl
  #
  # backend "s3" {}
}
