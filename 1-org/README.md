# Layer: 1-org

Per-tenant security perimeter. Deployed once per *(tenant, environment)*.

## Purpose

- **Security groups** — `main` and `apps` tiers, default-deny inbound, traffic
  allowed only between private subnets (`modules/security-group`).
- **Workload IAM** — one IAM application + least-privilege policy + API key per
  workload (Odoo, OpenClaw) — `iam.tf`.
- **Secret Manager** — Odoo master password generated with `random_password`
  and stored in Scaleway Secret Manager; optional OpenClaw API key — `secrets.tf`.

No secret value is ever placed in a `.tfvars` file.

## Dependencies

- `0-bootstrap` (state bucket).
- A tenant project (`tenant-provisioning` for Project-mode, or the tenant's own
  Organization for Org-mode).

## Deploy

```bash
make tenant-apply TENANT=<t> ENV=<env> LAYER=1-org
```

## Key inputs

| Name | Description |
|------|-------------|
| `environment` | `dev` / `prod` |
| `tenant` | Tenant short name |
| `cost_center` | Chargeback cost center |
| `billing_mode` | `project` / `org` |
| `project_id` | Tenant project ID |
| `openclaw_api_key` | Optional OpenClaw API key (sensitive, default `""`) |

## Outputs (consumed by 3-apps)

| Name | Description |
|------|-------------|
| `security_group_main_id` / `security_group_apps_id` | Security group IDs |
| `odoo_application_id` / `openclaw_application_id` | Workload IAM app IDs |
| `odoo_master_password_secret_id` | Secret Manager ID for the Odoo master password |
| `odoo_workload_access_key` / `odoo_workload_secret_key` | Odoo workload key (secret is sensitive) |
| `openclaw_workload_access_key` / `openclaw_workload_secret_key` | OpenClaw workload key |
