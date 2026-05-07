/**
 * Provider Configuration for Scaleway
 * European cloud provider - GDPR compliant by design
 */

terraform {
  required_version = ">= 1.5"
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.0"
    }
  }
}

provider "scaleway" {
  # Configuration via environment variables:
  # export SCW_ACCESS_KEY="SCWXXXXXXXXXXXXXXXXX"
  # export SCW_SECRET_KEY="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  # export SCW_DEFAULT_PROJECT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  # export SCW_DEFAULT_REGION="fr-par"  # Paris (EU)
  # export SCW_DEFAULT_ZONE="fr-par-1"
}
