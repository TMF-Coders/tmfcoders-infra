/**
 * IAM - Workload Identities (Scaleway)
 * One IAM application per workload, each with a least-privilege policy.
 * Workloads authenticate with their own API key - never a human user key.
 * API keys carry an expiry; time_rotating forces yearly rotation.
 */

resource "time_rotating" "workload_keys" {
  rotation_days = 365
}

#───────────────────────────────────────────────
# Odoo workload identity
#───────────────────────────────────────────────
resource "scaleway_iam_application" "odoo" {
  name        = "${var.tenant}-${var.environment}-odoo"
  description = "Odoo ERP workload identity (${var.environment})"
}

resource "scaleway_iam_policy" "odoo" {
  name           = "${var.tenant}-${var.environment}-odoo-policy"
  description    = "Odoo: read its own secrets, write observability data"
  application_id = scaleway_iam_application.odoo.id

  rule {
    project_ids = [var.project_id]
    permission_set_names = [
      "SecretManagerReadOnly",
      "ObservabilityFullAccess",
    ]
  }
}

resource "scaleway_iam_api_key" "odoo" {
  application_id     = scaleway_iam_application.odoo.id
  description        = "Odoo workload API key (${var.environment})"
  default_project_id = var.project_id
  expires_at         = time_rotating.workload_keys.rotation_rfc3339
}

#───────────────────────────────────────────────
# OpenClaw workload identity
#───────────────────────────────────────────────
resource "scaleway_iam_application" "openclaw" {
  name        = "${var.tenant}-${var.environment}-openclaw"
  description = "OpenClaw workload identity (${var.environment})"
}

resource "scaleway_iam_policy" "openclaw" {
  name           = "${var.tenant}-${var.environment}-openclaw-policy"
  description    = "OpenClaw: read its own secrets, write observability data"
  application_id = scaleway_iam_application.openclaw.id

  rule {
    project_ids = [var.project_id]
    permission_set_names = [
      "SecretManagerReadOnly",
      "ObservabilityFullAccess",
    ]
  }
}

resource "scaleway_iam_api_key" "openclaw" {
  application_id     = scaleway_iam_application.openclaw.id
  description        = "OpenClaw workload API key (${var.environment})"
  default_project_id = var.project_id
  expires_at         = time_rotating.workload_keys.rotation_rfc3339
}

#───────────────────────────────────────────────
# Scheduler workload identity (VM power off/on)
#───────────────────────────────────────────────
resource "scaleway_iam_application" "scheduler" {
  name        = "${var.tenant}-${var.environment}-scheduler"
  description = "VM power scheduler workload identity (${var.environment})"
}

resource "scaleway_iam_policy" "scheduler" {
  name           = "${var.tenant}-${var.environment}-scheduler-policy"
  description    = "Scheduler: power instances off/on in the tenant project"
  application_id = scaleway_iam_application.scheduler.id

  rule {
    project_ids          = [var.project_id]
    permission_set_names = ["InstancesFullAccess"]
  }
}

resource "scaleway_iam_api_key" "scheduler" {
  application_id     = scaleway_iam_application.scheduler.id
  description        = "Scheduler workload API key (${var.environment})"
  default_project_id = var.project_id
  expires_at         = time_rotating.workload_keys.rotation_rfc3339
}
