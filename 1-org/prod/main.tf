/**
 * Organization Layer - Production Environment (Scaleway)
 * Equivalent to GCP 1-org layer
 * Creates projects and security groups
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
    key    = "1-org/prod/terraform.tfstate"
    region = "fr-par"
    endpoint = "s3.fr-par.scw.cloud"
  }
}

provider "scaleway" {}

locals {
  environment = "prod"
  region      = "fr-par" # Paris (GDPR - EU)
  
  common_labels = {
    environment  = local.environment
    managed_by   = "terraform"
    organization = "tmfcoders"
  }
}

# Main Project (Equivalent to Host Project)
module "project_tmfcoders" {
  source = "../../modules/project"

  project_name = "TMF Coders - ${upper(local.environment)}"
  description  = "Main project for TMF Coders infrastructure"
}

# Security Group - Main (Equivalent to IAM + Org Policies)
module "security_group_main" {
  source = "../../modules/security-group"

  security_group_name = "tmfcoders-main-${local.environment}"
  description       = "Main security group - restrictive (PROD)"

  inbound_default_policy  = "drop" # Default DROP (equivalent to Org Policies)
  outbound_default_policy = "accept"

  # NO SSH from internet (use bastion or VPN)
  allow_ssh = false

  # NO direct web access (use Load Balancer)
  allow_web = false

  # Custom rules for internal communication
  inbound_rules = [
    {
      action = "accept"
      port   = "22"
      ip     = "10.10.0.0/16" # Private network only
    }
  ]

  outbound_rules = [
    {
      action = "accept"
      port   = "22"
      ip     = "10.10.0.0/16"
    }
  ]
}

# Security Group - Apps (Equivalent to Service Project)
module "security_group_apps" {
  source = "../../modules/security-group"

  security_group_name = "tmfcoders-apps-${local.environment}"
  description       = "Apps security group - Odoo + OpenClaw"

  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  allow_ssh = false # IAP equivalent: use private network

  inbound_rules = [
    {
      action = "accept"
      port   = "8069" # Odoo HTTP
      ip     = "10.10.20.0/24" # Apps subnet
    },
    {
      action = "accept"
      port   = "8072" # Odoo longpolling
      ip     = "10.10.20.0/24"
    }
  ]
}

output "project_id" {
  description = "Main Project ID"
  value       = module.project_tmfcoders.project_id
}

output "security_group_main_id" {
  description = "Main Security Group ID"
  value       = module.security_group_main.security_group_id
}

output "security_group_apps_id" {
  description = "Apps Security Group ID"
  value       = module.security_group_apps.security_group_id
}
