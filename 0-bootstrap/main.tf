/**
 * Bootstrap Layer - Scaleway
 * Creates API keys and initial configuration
 * Scaleway uses API keys instead of service accounts
 */

terraform {
  required_version = ">= 1.5"
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    bucket = "tmfcoders-terraform-state"
    key    = "bootstrap/terraform.tfstate"
    region = "fr-par" # Paris (EU)
    endpoint = "s3.fr-par.scw.cloud"
    
    # Scaleway S3 credentials via environment variables:
    # export AWS_ACCESS_KEY_ID="SCWXXXXXXXXXXXXXX"
    # export AWS_SECRET_ACCESS_KEY="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    # export AWS_DEFAULT_REGION="fr-par"
  }
}

provider "scaleway" {}

locals {
  environment = "bootstrap"
  region      = "fr-par" # Paris (GDPR - EU)
  
  common_labels = {
    environment  = local.environment
    managed_by   = "terraform"
    organization = "tmfcoders"
  }
}

# Create a project (equivalent to GCP project)
module "project_tmfcoders" {
  source = "../../modules/project"

  project_name = "TMF Coders - Infrastructure"
  description  = "Main project for TMF Coders infrastructure"
}

# Outputs
output "project_id" {
  description = "Project ID"
  value       = module.project_tmfcoders.project_id
}

output "api_key_instructions" {
  description = "How to get API credentials"
  value       = <<-EOT
    To get Scaleway API credentials:
    1. Go to: https://console.scaleway.com/iam/api-keys
    2. Create a new API key
    3. Set environment variables:
       export SCW_ACCESS_KEY="SCWXXXXXXXXXXXXXX"
       export SCW_SECRET_KEY="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
       export SCW_DEFAULT_PROJECT_ID="${module.project_tmfcoders.project_id}"
       export SCW_DEFAULT_REGION="fr-par"
       export SCW_DEFAULT_ZONE="fr-par-1"
    EOT
}
