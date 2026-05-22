# Layer: tenant-provisioning

Creates one Scaleway Project per **Project-mode** tenant/environment inside the
home Organization. Each Project is an independent billing unit.

## Purpose

- Iterates `var.tenant_projects` and calls `modules/tenant` for each entry.
- Optionally creates a scoped read-only IAM application per tenant (delegated
  client visibility).
- Outputs the created `project_id` values — copy them into each tenant's
  `tenants/<tenant>/<env>/*.tfvars`.

**Org-mode** tenants are NOT managed here — they live in their own
Organization and use their own `0-bootstrap` run.

## Dependencies

- `0-bootstrap` (state bucket).

## Deploy

```bash
# edit terraform.tfvars: one entry per Project-mode tenant/environment
make tp-init
make tp-apply
make tp-output            # note the project IDs
```

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| `region` | Scaleway region | `"fr-par"` |
| `zone` | Scaleway zone | `"fr-par-1"` |
| `tenant_projects` | Map of tenant/env projects to create | `{}` |

### `tenant_projects` entry

| Field | Type | Default |
|-------|------|---------|
| `tenant` | `string` | required |
| `project_name` | `string` | required |
| `description` | `string` | `""` |
| `create_client_access` | `bool` | `false` |
| `client_permission_sets` | `list(string)` | `["ProjectReadOnly","BillingReadOnly"]` |

## Outputs

| Name | Description |
|------|-------------|
| `tenant_project_ids` | Map of tenant slug → project ID |
| `client_access_keys` | Map of tenant slug → client access key |
| `client_secret_keys` | Map of tenant slug → client secret key (sensitive) |
