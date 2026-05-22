# Runbook - TMF Coders Infrastructure (Scaleway, multi-tenant)

Operational procedures for deploying and maintaining the infrastructure.

## Prerequisites

```bash
terraform version   # >= 1.10
scw version         # optional, Scaleway CLI
jq --version        # required by scripts/rebill.sh

# Scaleway API credentials (IAM application key, never a personal key)
export SCW_ACCESS_KEY="SCWXXXXXXXXXXXXXXXXX"
export SCW_SECRET_KEY="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# The S3-compatible backend reuses the same credentials via AWS variables
export AWS_ACCESS_KEY_ID="$SCW_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$SCW_SECRET_KEY"
```

## 1. Landing zone (once per Organization)

```bash
./init.sh                       # scaffolds the shared-root terraform.tfvars
# edit 0-bootstrap/terraform.tfvars  (state_bucket_suffix etc.)

make bootstrap-apply            # local state: state bucket + CI IAM + platform project
```

Record the outputs:
```bash
terraform -chdir=0-bootstrap output state_bucket_name
terraform -chdir=0-bootstrap output -raw terraform_ci_secret_key   # -> GitHub secret
```

Put `state_bucket_name` into every `backend.hcl` (shared roots and
`tenants/**`). Then migrate the bootstrap state:
```bash
make bootstrap-migrate
```

Repeat this section against each **Org-mode** client's Organization (its own
credentials, its own state bucket).

## 2. Create Project-mode tenant projects

```bash
# edit tenant-provisioning/terraform.tfvars - one entry per tenant/env
make tp-init
make tp-apply
make tp-output                  # note each tenant's project_id
```

## 3. Onboard a tenant

```bash
scripts/new-tenant.sh <tenant> <env> <billing_mode> <cost_center> \
  <project_id> <state_bucket> <suffix> <alert_email>
```

Example (Project-mode):
```bash
scripts/new-tenant.sh acme prod project client-acme \
  <acme_project_id> tmfcoders-terraform-state-xxxx acmexxx ops@acme.example
```

Review the generated files under `tenants/<tenant>/<env>/`.

## 4. Deploy a tenant

Order matters — each layer consumes the previous layer's remote state.

```bash
make tenant-apply-all TENANT=acme ENV=prod
```

Or layer by layer:
```bash
make tenant-apply TENANT=acme ENV=prod LAYER=1-org
make tenant-apply TENANT=acme ENV=prod LAYER=2-network
make tenant-apply TENANT=acme ENV=prod LAYER=3-apps
make tenant-apply TENANT=acme ENV=prod LAYER=4-observability
```

`tenant-init`/`tenant-plan`/`tenant-apply` re-`init -reconfigure` the layer
against the tenant's backend, so switching tenants is safe.

## 5. Day-2 operations

| Task | Command |
|------|---------|
| Plan a change | `make tenant-plan TENANT=acme ENV=prod LAYER=3-apps` |
| Show outputs | `make tenant-output TENANT=acme ENV=prod LAYER=3-apps` |
| Local quality gate | `make check` |
| Monthly cost report | `make rebill` |
| SSH to a VM | via the Public Gateway bastion, port 61000 |

### Connect to a VM through the bastion

```bash
make tenant-init TENANT=acme ENV=prod LAYER=2-network
GW_IP=$(terraform -chdir=2-network output -raw public_gateway_ip)
ssh -J bastion@${GW_IP}:61000 root@<vm-private-ip>
```

### Rotate a secret

```bash
scw secret version create secret-id=<id> data=$(openssl rand -base64 32)
```

## 6. Billing / rebill

```bash
export SCW_DEFAULT_ORGANIZATION_ID="..."
export REBILL_MARKUP_PCT="15"
make rebill
```
Map each `project_id` to a tenant with `make tp-output`, then invoice clients.
Org-mode clients are billed by Scaleway directly.

## 7. Disaster recovery

- **State**: backend bucket is versioned; restore a prior object version.
- **PostgreSQL**: Managed Database automated daily backups
  (`rdb_backup_retention_days`). Restore via the Scaleway console or API.
- **Audit logs**: immutable for 730 days (Object Lock, COMPLIANCE) — cannot be
  deleted before expiry, by design.

## 8. Teardown (per tenant, reverse order)

```bash
make tenant-destroy TENANT=acme ENV=prod LAYER=4-observability
make tenant-destroy TENANT=acme ENV=prod LAYER=3-apps
make tenant-destroy TENANT=acme ENV=prod LAYER=2-network
make tenant-destroy TENANT=acme ENV=prod LAYER=1-org
```

The audit-log bucket cannot be emptied until Object Lock retention expires.
