# Layer: 3-apps

Per-tenant application workloads. Deployed once per *(tenant, environment)*.

## Purpose

- **OpenClaw VM** (Matriz) — private-only, on the `tmf` network.
- **Odoo 17 VM** (Filial) — private-only, on the `apps` network.
- **Managed PostgreSQL** (`scaleway_rdb_instance`) — HA in prod, automated
  backups, attached to the `apps` private network via IPAM.
- **HTTPS Load Balancer** — the only public ingress to Odoo (optional).
- The Odoo DB password is generated (`random_password`) and stored in Secret
  Manager; cloud-init pulls secrets at boot using the workload IAM key.

## Dependencies

- `0-bootstrap` (state bucket).
- `1-org` — security groups, workload IAM keys, master-password secret ID
  (via `terraform_remote_state`).
- `2-network` — private network IDs (via `terraform_remote_state`).

## Deploy

```bash
make tenant-apply TENANT=<t> ENV=<env> LAYER=3-apps
```

## Key inputs

| Name | Description | Default |
|------|-------------|---------|
| `environment`, `tenant`, `cost_center`, `billing_mode`, `project_id` | Tenant dimensions | — |
| `state_bucket` | State bucket for cross-layer reads | required |
| `openclaw_instance_type` | OpenClaw VM type | `"PRO2-S"` |
| `odoo_instance_type` | Odoo VM type | `"PRO2-M"` |
| `rdb_node_type` | Managed PostgreSQL node type | `"DB-GP-S"` |
| `rdb_is_ha` | HA PostgreSQL cluster | `true` |
| `rdb_backup_retention_days` | Backup retention | `30` |
| `enable_odoo_load_balancer` | Provision the public LB | `true` |
| `odoo_domain` | DNS name for the LB TLS cert (empty = HTTP-only) | `""` |

## Outputs

| Name | Description |
|------|-------------|
| `openclaw_instance_id` / `odoo_instance_id` | Instance IDs |
| `odoo_db_endpoint` / `odoo_db_name` | Managed PostgreSQL endpoint and DB |
| `odoo_db_password_secret_id` | Secret Manager ID for the DB password |
| `odoo_load_balancer_ip` / `odoo_url` | Public LB IP and URL |
