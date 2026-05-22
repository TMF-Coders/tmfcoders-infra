# Layer: 4-observability

Per-tenant observability and compliance. Deployed once per *(tenant, environment)*.

## Purpose

Three pillars:

1. **Logs & metrics** — Scaleway Cockpit sources (managed Grafana + Loki +
   Mimir), an ingestion token for agents, an editor-role Grafana account.
2. **Immutable audit archive** — Object Storage bucket with Object Lock in
   COMPLIANCE mode and a 730-day lifecycle (GDPR retention). Objects cannot be
   deleted or overwritten before expiry.
3. **Alerting** — Cockpit Alert Manager with managed alerts and an email
   contact point.

## Dependencies

- `0-bootstrap` (state bucket).
- A tenant project.

## Deploy

```bash
make tenant-apply TENANT=<t> ENV=<env> LAYER=4-observability
```

## Key inputs

| Name | Description | Default |
|------|-------------|---------|
| `environment`, `tenant`, `cost_center`, `billing_mode`, `project_id` | Tenant dimensions | — |
| `alert_email` | Email for Cockpit alerts (validated) | required |
| `audit_retention_days` | Immutable audit retention (365-3650) | `730` |
| `cockpit_retention_days` | Cockpit source retention (1-365) | `31` |
| `state_bucket_suffix` | Globally-unique suffix for the audit bucket | required |

## Outputs

| Name | Description |
|------|-------------|
| `cockpit_logs_source_url` / `cockpit_metrics_source_url` | Cockpit push URLs |
| `cockpit_ingest_token` | Ingestion token for agents (sensitive) |
| `grafana_user_login` / `grafana_user_password` | Grafana account (password sensitive) |
| `audit_logs_bucket` / `audit_logs_endpoint` | Immutable audit bucket |

## Note

`enable_managed_alerts` emits a provider deprecation warning; it remains
functional. Migrate to `preconfigured_alert_ids` when the provider stabilises.
