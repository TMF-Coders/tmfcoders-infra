/**
 * Secret Manager (Scaleway)
 * Centralised, encrypted secret storage. No credentials live in code or
 * .tfvars files: the Odoo master password is generated here and stored
 * straight into Secret Manager. Rotate via a new secret_version.
 */

locals {
  secret_path = "/tenants/${var.tenant}/${var.environment}"
}

#───────────────────────────────────────────────
# Odoo master/admin password (generated, never in tfvars)
#───────────────────────────────────────────────
resource "random_password" "odoo_master_password" {
  length           = 32
  special          = true
  override_special = "!@#%*-_=+"
}

resource "scaleway_secret" "odoo_master_password" {
  name        = "${var.tenant}-${var.environment}-odoo-master-password"
  description = "Odoo master/admin password"
  project_id  = var.project_id
  path        = local.secret_path
  tags        = ["odoo", "master-password", var.environment]
}

resource "scaleway_secret_version" "odoo_master_password" {
  secret_id = scaleway_secret.odoo_master_password.id
  data      = random_password.odoo_master_password.result
}

#───────────────────────────────────────────────
# OpenClaw API key (created only when provided)
#───────────────────────────────────────────────
resource "scaleway_secret" "openclaw_api_key" {
  count = var.openclaw_api_key != "" ? 1 : 0

  name        = "${var.tenant}-${var.environment}-openclaw-api-key"
  description = "OpenClaw application API key"
  project_id  = var.project_id
  path        = local.secret_path
  tags        = ["openclaw", "api-key", var.environment]
}

resource "scaleway_secret_version" "openclaw_api_key" {
  count = var.openclaw_api_key != "" ? 1 : 0

  secret_id = scaleway_secret.openclaw_api_key[0].id
  data      = var.openclaw_api_key
}
