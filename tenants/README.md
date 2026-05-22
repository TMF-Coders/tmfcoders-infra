# tenants/

Per-tenant deployment configuration. Each tenant is a deployment of the
canonical layers (`1-org`..`4-observability`).

## Layout

```
tenants/<tenant>/<env>/
  1-org.backend.hcl          state key for (tenant, env, 1-org)
  1-org.tfvars               variable values for that layer
  2-network.backend.hcl
  2-network.tfvars
  3-apps.backend.hcl
  3-apps.tfvars
  4-observability.backend.hcl
  4-observability.tfvars
```

- `_template/prod/` holds the placeholder files (`__TENANT__`, `__ENV__`,
  `__PROJECT_ID__`, `__BUCKET__`, `__SUFFIX__`, `__COST_CENTER__`,
  `__BILLING_MODE__`, `__ALERT_EMAIL__`).
- Generate a real tenant with `scripts/new-tenant.sh`.

## Example tenants

| Tenant | `billing_mode` | Notes |
|--------|----------------|-------|
| `tmf-internal` | `project` | TMF Coders internal workloads |
| `acme` | `project` | Client as a Project in the home Org |
| `bigbank` | `org` | Client owning its own Scaleway Organization |

## Why these `.tfvars` are committed

Tenant `.tfvars` carry no secrets — only the tenant inventory (project IDs,
sizing, cost center). Secrets are always generated and stored in Secret
Manager. `.gitignore` keeps `*.tfvars` ignored everywhere except here
(`!tenants/**/*.tfvars`); `gitleaks` scans every commit as a backstop.

## Deploy

```bash
make tenant-apply-all TENANT=<tenant> ENV=<env>
```
