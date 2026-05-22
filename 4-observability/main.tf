/**
 * Observability Layer - Scaleway
 * Three pillars:
 *   1. Centralised logs/metrics via Scaleway Cockpit (Grafana + Loki + Mimir).
 *   2. Immutable audit-log archive in Object Storage with Object Lock (730d).
 *   3. Managed alerting via the Cockpit Alert Manager.
 */

locals {
  name_prefix = "${var.tenant}-${var.environment}"

  common_tags = {
    environment  = var.environment
    tenant       = var.tenant
    cost_center  = var.cost_center
    billing_mode = var.billing_mode
    billable     = "true"
    managed_by   = "terraform"
    purpose      = "observability"
    organization = "tmfcoders"
  }
}

#═══════════════════════════════════════════════════════
# PILLAR 1: Centralised logs & metrics (Cockpit)
#═══════════════════════════════════════════════════════
resource "scaleway_cockpit_source" "logs" {
  project_id     = var.project_id
  name           = "${local.name_prefix}-logs"
  type           = "logs"
  region         = var.region
  retention_days = var.cockpit_retention_days
}

resource "scaleway_cockpit_source" "metrics" {
  project_id     = var.project_id
  name           = "${local.name_prefix}-metrics"
  type           = "metrics"
  region         = var.region
  retention_days = var.cockpit_retention_days
}

# Ingestion token for VMs / agents to push logs and metrics.
resource "scaleway_cockpit_token" "ingest" {
  project_id = var.project_id
  name       = "${local.name_prefix}-ingest"
  region     = var.region

  scopes {
    write_logs    = true
    write_metrics = true
    write_traces  = false
    query_logs    = false
    query_metrics = false
    query_traces  = false
  }
}

# Read-only Grafana account for the operations team.
resource "scaleway_cockpit_grafana_user" "ops" {
  project_id = var.project_id
  login      = "tmf-ops-${var.environment}"
  role       = "editor"
}

#═══════════════════════════════════════════════════════
# PILLAR 2: Immutable audit-log archive (Object Lock)
#═══════════════════════════════════════════════════════
resource "scaleway_object_bucket" "audit_logs" {
  name       = "${var.tenant}-audit-logs-${var.environment}-${var.state_bucket_suffix}"
  project_id = var.project_id
  region     = var.region

  # Object Lock requires versioning and must be enabled at creation.
  object_lock_enabled = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "expire-after-retention"
    enabled = true

    expiration {
      days = var.audit_retention_days
    }
  }

  tags = merge(local.common_tags, {
    purpose    = "audit-logs"
    compliance = "gdpr"
    retention  = "${var.audit_retention_days}-days"
  })
}

resource "scaleway_object_bucket_acl" "audit_logs" {
  bucket = scaleway_object_bucket.audit_logs.name
  acl    = "private"
}

# COMPLIANCE mode: objects cannot be deleted or overwritten until expiry.
resource "scaleway_object_bucket_lock_configuration" "audit_logs" {
  bucket = scaleway_object_bucket.audit_logs.name

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = var.audit_retention_days
    }
  }
}

#═══════════════════════════════════════════════════════
# PILLAR 3: Managed alerting (Cockpit Alert Manager)
#═══════════════════════════════════════════════════════
resource "scaleway_cockpit_alert_manager" "main" {
  project_id            = var.project_id
  region                = var.region
  enable_managed_alerts = true

  contact_points {
    email = var.alert_email
  }
}
