/**
 * Bootstrap Layer - Scaleway Landing Zone
 * Run ONCE per Organization. Creates the shared foundation:
 *   - the platform (landing-zone) Project - shared, non-client-billable
 *   - the Object Storage bucket holding remote Terraform state
 *   - the IAM application + Organization-wide policy used by the CI pipeline
 *
 * For Org-mode tenants, run this layer again against that Organization's
 * credentials. Project-mode tenants get their Projects from tenant-provisioning.
 *
 * Runs on local state, then migrates to the bucket it just created.
 * See: versions.tf, providers.tf, backend.hcl.example
 */

locals {
  # Landing-zone resources are shared overhead, not billable to any tenant.
  common_tags = {
    environment  = "landing-zone"
    tenant       = "platform"
    cost_center  = "platform"
    billable     = "false"
    managed_by   = "terraform"
    organization = "tmfcoders"
  }
}

#───────────────────────────────────────────────
# Platform (landing-zone) project
#───────────────────────────────────────────────
module "project" {
  source = "../modules/project"

  project_name = var.project_name
  description  = "TMF Coders - landing-zone / platform project (shared foundation)"
}

#───────────────────────────────────────────────
# Remote state bucket (versioned, private)
#───────────────────────────────────────────────
resource "scaleway_object_bucket" "state" {
  name       = "${var.state_bucket_name}-${var.state_bucket_suffix}"
  project_id = module.project.project_id
  region     = var.region
  tags       = local.common_tags

  # Versioning protects state against corruption and accidental deletion.
  versioning {
    enabled = true
  }
}

# Object buckets are private by default; ACLs are not used.

#───────────────────────────────────────────────
# CI/CD IAM application (Organization-wide - deploys every tenant)
#───────────────────────────────────────────────
resource "scaleway_iam_application" "terraform_ci" {
  name        = "tmfcoders-terraform-ci"
  description = "Service identity used by the GitHub Actions Terraform pipeline"
}

resource "scaleway_iam_policy" "terraform_ci" {
  name           = "tmfcoders-terraform-ci-policy"
  description    = "Permissions for the Terraform CI pipeline across all tenant projects"
  application_id = scaleway_iam_application.terraform_ci.id

  # Project-scoped permissions, granted org-wide (every tenant project).
  rule {
    organization_id      = module.project.organization_id
    permission_set_names = ["AllProductsFullAccess"]
  }

  # Organization-scoped permissions: create projects, manage workload IAM.
  rule {
    organization_id      = module.project.organization_id
    permission_set_names = ["ProjectManager", "IAMManager"]
  }
}

# API keys must carry an expiry; time_rotating forces yearly rotation.
resource "time_rotating" "ci_key" {
  rotation_days = 365
}

# API key for the CI application. The secret is shown once - store it in the
# GitHub repository secrets and never commit it.
resource "scaleway_iam_api_key" "terraform_ci" {
  application_id     = scaleway_iam_application.terraform_ci.id
  description        = "GitHub Actions Terraform CI key"
  default_project_id = module.project.project_id
  expires_at         = time_rotating.ci_key.rotation_rfc3339
}
