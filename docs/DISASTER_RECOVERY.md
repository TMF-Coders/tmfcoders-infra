# Disaster Recovery - TMF Coders Infrastructure

Recovery procedures and objectives.

## Objectives

| Asset | RPO | RTO | Mechanism |
|-------|-----|-----|-----------|
| Terraform state | near-zero | minutes | Versioned Object Storage bucket |
| PostgreSQL data | <= 24 h | < 1 h | Managed Database automated backups |
| Audit logs | zero | n/a | Object Lock (immutable, cannot be lost) |
| VMs / config | n/a (rebuildable) | ~15 min | `terraform apply` + cloud-init |

VMs are cattle: they hold no durable state (Odoo data lives in Managed
PostgreSQL). Recovery of a VM = re-apply the layer.

## Scenario: corrupted / lost Terraform state

The state bucket is versioned.

```bash
# list versions
scw object-storage ... # or Scaleway console -> bucket -> object versions
# restore the previous version of tenants/<t>/<layer>/<env>/terraform.tfstate
```

If state is unrecoverable, re-import resources with `terraform import` using
the IDs from the Scaleway console.

## Scenario: PostgreSQL data loss / corruption

Managed Database keeps automated daily backups for `rdb_backup_retention_days`.

```bash
# Scaleway console -> Managed Database -> <instance> -> Backups -> Restore
# or via API / scw CLI: create a new instance from a backup
```

Update `3-apps` outputs / Odoo config if the endpoint changes.

## Scenario: VM lost or unhealthy

```bash
make tenant-apply TENANT=<t> ENV=<env> LAYER=3-apps
```

Terraform recreates the instance; cloud-init reinstalls the workload and
re-pulls secrets from Secret Manager. Odoo reconnects to the unchanged
Managed PostgreSQL.

## Scenario: full tenant rebuild

```bash
make tenant-apply-all TENANT=<t> ENV=<env>
```

Deploys all four layers in order. Secrets are regenerated unless the prior
Secret Manager entries still exist.

## Scenario: lost CI credentials

Recreate `scaleway_iam_api_key.terraform_ci` in `0-bootstrap`
(`terraform taint` + `apply`) and update the GitHub repository secrets.

## Scenario: region outage

EU regions are independent. To fail over, set `region` (and `zone`) to another
EU region (`nl-ams`, `pl-waw`) in the tenant `.tfvars` and re-apply. Data must
first be migrated (DB backup restore in the target region, audit archive
re-created — Object Lock prevents moving the existing one).

## Backups summary

| What | Where | Retention |
|------|-------|-----------|
| Terraform state | State bucket, versioned | 90+ days of versions |
| PostgreSQL | Managed Database backups | `rdb_backup_retention_days` |
| Audit logs | Object Lock bucket | `audit_retention_days` (730) |

## Test cadence

- Quarterly: restore a PostgreSQL backup into a scratch instance.
- Quarterly: restore a prior state version in a non-prod tenant.
- Annually: full tenant rebuild drill in `dev`.
