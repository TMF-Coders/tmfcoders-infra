# Observability - TMF Coders Infrastructure

Per-tenant observability, delivered by layer `4-observability`.

## Three pillars

### 1. Logs & metrics — Scaleway Cockpit

Cockpit is Scaleway's managed observability stack (Grafana + Loki + Mimir).

| Resource | Purpose |
|----------|---------|
| `scaleway_cockpit_source.logs` | Logs data source, retention `cockpit_retention_days` |
| `scaleway_cockpit_source.metrics` | Metrics data source |
| `scaleway_cockpit_token.ingest` | Write-only token for log/metric agents |
| `scaleway_cockpit_grafana_user.ops` | Editor-role Grafana account |

VMs ship logs/metrics to the source URLs using the ingestion token. View
dashboards in the Scaleway Cockpit Grafana with the `ops` account.

### 2. Immutable audit archive — Object Storage + Object Lock

| Resource | Purpose |
|----------|---------|
| `scaleway_object_bucket.audit_logs` | Versioned audit-log bucket |
| `scaleway_object_bucket_lock_configuration` | Object Lock, COMPLIANCE mode |
| `scaleway_object_bucket_acl` | Private ACL |

- Object Lock COMPLIANCE: objects cannot be deleted or overwritten before the
  retention period (`audit_retention_days`, default 730 = GDPR 2 years).
- Lifecycle rule expires objects after retention.
- Even an account administrator cannot remove a locked object early — by design.

### 3. Alerting — Cockpit Alert Manager

| Resource | Purpose |
|----------|---------|
| `scaleway_cockpit_alert_manager.main` | Managed alerts + email contact point |

Managed alerts cover infrastructure health (CPU, memory, availability).
The contact point is `alert_email`.

## Retention

| Data | Retention | Mechanism |
|------|-----------|-----------|
| Cockpit logs/metrics | `cockpit_retention_days` (default 31, max 365) | Cockpit source |
| Audit archive | `audit_retention_days` (default 730) | Object Lock + lifecycle |

For retention beyond Cockpit's 365-day ceiling, ship logs to the Object
Storage audit bucket — it holds them immutably for the full GDPR window.

## Per-tenant isolation

Each tenant runs its own `4-observability` deployment: separate Cockpit
sources, separate audit bucket, separate alert contact. No tenant can see
another tenant's telemetry.

## Known limitation

`enable_managed_alerts` triggers a Scaleway provider deprecation warning
(suggests `preconfigured_alert_ids`). It remains functional; migrate when the
provider API stabilises.
