# Quick Start - TMF Coders Infrastructure

Fastest path from zero to a running tenant. Full detail in [RUNBOOK.md](RUNBOOK.md).

## 0. Prerequisites

```bash
terraform version      # >= 1.10
jq --version           # for the rebill script
git --version
```

Get a Scaleway IAM API key: https://console.scaleway.com/iam/api-keys

```bash
export SCW_ACCESS_KEY="SCWXXXXXXXXXXXXXXXXX"
export SCW_SECRET_KEY="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export AWS_ACCESS_KEY_ID="$SCW_ACCESS_KEY"        # S3-compatible backend
export AWS_SECRET_ACCESS_KEY="$SCW_SECRET_KEY"
```

## 1. Scaffold

```bash
./init.sh
```

Creates `terraform.tfvars` for `0-bootstrap` and `tenant-provisioning`.

## 2. Landing zone (once per Organization)

```bash
# edit 0-bootstrap/terraform.tfvars -> set a unique state_bucket_suffix
make bootstrap-apply

terraform -chdir=0-bootstrap output state_bucket_name   # note this
```

Put that bucket name into every `backend.hcl` (shared roots + `tenants/**`),
then migrate state:

```bash
make bootstrap-migrate
```

## 3. Create a tenant project (Project-mode)

```bash
# edit tenant-provisioning/terraform.tfvars -> add your tenant
make tp-init && make tp-apply
make tp-output                       # copy the tenant's project_id
```

## 4. Scaffold the tenant's config

```bash
scripts/new-tenant.sh acme prod project client-acme \
  <project_id> <state_bucket_name> <suffix> ops@acme.example
```

Review `tenants/acme/prod/*.tfvars`.

## 5. Deploy

```bash
make tenant-apply-all TENANT=acme ENV=prod
```

Deploys `1-org` -> `2-network` -> `3-apps` -> `4-observability` in order.

## 6. Verify

```bash
make tenant-output TENANT=acme ENV=prod LAYER=3-apps   # Odoo URL, IPs
make tenant-output TENANT=acme ENV=prod LAYER=2-network  # bastion IP/port
```

## 7. Bill the client

```bash
export SCW_DEFAULT_ORGANIZATION_ID="..."
export REBILL_MARKUP_PCT="15"
make rebill
```

## Common commands

| Goal | Command |
|------|---------|
| Plan one layer | `make tenant-plan TENANT=acme ENV=prod LAYER=3-apps` |
| Apply one layer | `make tenant-apply TENANT=acme ENV=prod LAYER=3-apps` |
| Outputs | `make tenant-output TENANT=acme ENV=prod LAYER=1-org` |
| Quality gate | `make check` |
| Cost report | `make rebill` |
| New tenant | `scripts/new-tenant.sh ...` |

## Org-mode tenant

For a client that owns its own Scaleway Organization: run steps 2-6 with that
Organization's credentials and its own state bucket; use `org` as the
`billing_mode` argument to `new-tenant.sh`. See [docs/BILLING.md](docs/BILLING.md).
