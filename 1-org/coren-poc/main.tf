/**
 * Landing Zone — Coren POC governance (org-level only)
 *
 * This layer lives in the central infra repo and owns ONLY the governance
 * boundary of the Coren POC compartment:
 *   - the dedicated Scaleway Project (isolated billing)
 *   - an IAM application + scoped API key that the *application* repo
 *     (coren-customer-platform) uses to deploy its own resources inside
 *     this project.
 *
 * The application stack (VM, IP, GenAI key, cloud-init) is NOT defined here.
 * It lives in coren-customer-platform/infra and consumes this layer's
 * outputs (project_id) via terraform_remote_state. Separation of duties:
 *   Platform/Ops owns the box; the app team owns what runs inside it.
 */

terraform {
  required_version = ">= 1.5"
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }

  backend "s3" {
    bucket   = "tmfcoders-terraform-state"
    key      = "1-org/coren-poc/terraform.tfstate"
    region   = "fr-par"
    endpoint = "s3.fr-par.scw.cloud"
  }
}

provider "scaleway" {}

locals {
  environment = "coren-poc"
  region      = "fr-par"
}

# ── Isolated project (separate billing line) ──
module "project_coren" {
  source = "../../modules/project"

  project_name = "Coren POC"
  description  = "Compartimento estanco — demo Asistente Horeca Coren (efímero)"
}

# ── Deploy identity for the app repo ──
# coren-customer-platform/infra authenticates with this key. Scoped to the
# Coren POC project only: it cannot touch prod or other tenants.
resource "scaleway_iam_application" "deploy" {
  name        = "coren-poc-deploy"
  description = "Deploy identity used by coren-customer-platform CI/CD"
}

resource "scaleway_iam_policy" "deploy" {
  name           = "coren-poc-deploy-policy"
  description    = "Scoped deploy permissions inside the Coren POC project"
  application_id = scaleway_iam_application.deploy.id

  # Everything the app needs to stand up its stack, but only in this project.
  rule {
    project_ids = [module.project_coren.project_id]
    permission_set_names = [
      "InstancesFullAccess",        # VM + IP
      "VPCFullAccess",              # private network (if used)
      "GenerativeApisFullAccess",   # Mistral / GenAI key creation
      "IAMManager",                 # create the GenAI application + key
    ]
  }
}

resource "time_rotating" "deploy_key" {
  rotation_days = 365
}

resource "scaleway_iam_api_key" "deploy" {
  application_id     = scaleway_iam_application.deploy.id
  description        = "coren-customer-platform deploy key"
  default_project_id = module.project_coren.project_id
  expires_at         = time_rotating.deploy_key.rotation_rfc3339
}

# ── Outputs consumed by the app repo via terraform_remote_state ──
output "project_id" {
  value       = module.project_coren.project_id
  description = "Coren POC project ID"
}

output "organization_id" {
  value       = module.project_coren.organization_id
  description = "Organization ID"
}

output "deploy_api_key_id" {
  value       = scaleway_iam_api_key.deploy.access_key
  description = "Deploy key access key (store as SCW_ACCESS_KEY in the app repo CI)"
}

output "deploy_api_key_secret" {
  value       = scaleway_iam_api_key.deploy.secret_key
  sensitive   = true
  description = "Deploy key secret — store as SCW_SECRET_KEY secret in the app repo CI"
}
