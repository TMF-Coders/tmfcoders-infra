# TMF Coders - Infrastructure as Code

Bank-grade, **multi-tenant** Infrastructure as Code on **Scaleway** — the EU
cloud, GDPR-compliant by design. Terraform, layered, with per-tenant billing
segmentation.

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.10-623CE4?logo=terraform)](https://www.terraform.io/)
[![Scaleway](https://img.shields.io/badge/Scaleway-Cloud-4F0599?logo=scaleway)](https://www.scaleway.com/)

## Model

A **hybrid** tenancy model — see [docs/BILLING.md](docs/BILLING.md):

| Tenant kind | Lives in | `billing_mode` | Pays Scaleway |
|-------------|----------|----------------|---------------|
| Landing zone / platform | Platform Project, home Org | n/a | TMF Coders |
| Internal / small clients | Project in home Org | `project` | TMF Coders, rebills |
| Client as legal entity | Its own Organization | `org` | The client directly |

Scaleway bills per **Organization** and reports consumption per **Project** —
so a Project per tenant gives a native cost breakdown for chargeback.

## Layers

| Layer | Scope | Component |
|-------|-------|-----------|
| `0-bootstrap` | per Organization | Landing zone: state bucket, CI IAM, platform project |
| `tenant-provisioning` | home Organization | Creates Project-mode tenant projects |
| `1-org` | per tenant/env | Security groups, workload IAM, Secret Manager |
| `2-network` | per tenant/env | VPC v2, private networks, Public Gateway + bastion |
| `3-apps` | per tenant/env | OpenClaw + Odoo 19 VMs, Managed PostgreSQL, Load Balancer |
| `4-observability` | per tenant/env | Cockpit logs/metrics/alerts, immutable audit archive |

`1-org`..`4-observability` are single canonical roots. A deployment =
*(tenant, environment)* selected via `backend.hcl` + `.tfvars` under
`tenants/<tenant>/<env>/`.

## Repository layout

```
.
├── 0-bootstrap/            # landing zone, run once per Organization
├── tenant-provisioning/    # creates Project-mode tenant projects
├── 1-org/ 2-network/ 3-apps/ 4-observability/   # canonical layer code
├── modules/
│   ├── project/  network/  instance/  security-group/
│   └── tenant/             # tenant Project + scoped client IAM
├── tenants/
│   ├── _template/prod/     # placeholder backend.hcl + tfvars
│   ├── tmf-internal/prod/  # internal workloads (Project-mode)
│   ├── acme/prod/          # example client (Project-mode)
│   └── bigbank/prod/       # example client (Org-mode)
├── scripts/
│   ├── new-tenant.sh       # scaffold a tenant from the template
│   └── rebill.sh           # monthly per-tenant cost report
├── .github/workflows/      # CI quality gate
└── Makefile
```

## Quick start

```bash
./init.sh                                  # prerequisites + scaffold tfvars

export SCW_ACCESS_KEY="SCWXXXXXXXXXXXXXXXXX"
export SCW_SECRET_KEY="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export AWS_ACCESS_KEY_ID="$SCW_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$SCW_SECRET_KEY"

make bootstrap-apply                       # landing zone (once)
make bootstrap-migrate                     # state -> remote bucket

make tp-init && make tp-apply              # create tenant projects
make tp-output                             # note each project_id

make tenant-apply-all TENANT=acme ENV=prod # deploy a tenant, all layers
```

Per-layer: `make tenant-apply TENANT=acme ENV=prod LAYER=2-network`.

## Billing

```bash
export SCW_DEFAULT_ORGANIZATION_ID="..."
export REBILL_MARKUP_PCT="15"
make rebill                                # per-project cost + markup
```

## Security highlights

- No VM has a public IP. SSH only through the Public Gateway bastion.
- Public traffic reaches Odoo solely via the Load Balancer (HTTPS).
- Default-deny security groups; traffic only between private subnets.
- One least-privilege IAM application per workload; org-wide CI identity.
- Secrets generated and stored in Secret Manager — never in `.tfvars`.
- Per-tenant state isolation; private, versioned bucket with state locking.
- Audit logs immutable for 730 days (Object Lock, COMPLIANCE mode).
- EU regions only, enforced by variable validation.
- Every resource tagged `tenant` / `cost-center` / `billing-mode` / `billable`.

## Quality gate

`make check` locally; CI runs fmt/validate, tflint, tfsec, checkov, gitleaks,
terraform-docs and infracost on every PR.

## Documentation

| Document | Content |
|----------|---------|
| [QUICK_START.md](QUICK_START.md) | Fastest path to a running tenant |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Tenancy model, layers, security design |
| [RUNBOOK.md](RUNBOOK.md) | Step-by-step operational procedures |
| [DIRECTORY_STRUCTURE.md](DIRECTORY_STRUCTURE.md) | Annotated repository layout |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Workflow and conventions |
| [docs/BILLING.md](docs/BILLING.md) | Cost segmentation and rebilling |
| [docs/MIGRATION.md](docs/MIGRATION.md) | Migrating the existing deployment into the landing zone |
| [docs/IAM.md](docs/IAM.md) | Identities, policies, permission sets |
| [docs/NETWORKING.md](docs/NETWORKING.md) | Topology, address plan, bastion |
| [docs/SECURITY.md](docs/SECURITY.md) | Controls, threat model, hardening |
| [docs/OBSERVABILITY.md](docs/OBSERVABILITY.md) | Cockpit, audit archive, alerting |
| [docs/DISASTER_RECOVERY.md](docs/DISASTER_RECOVERY.md) | RPO/RTO, restore procedures |

Each layer and module also carries its own `README.md`.

## Requirements

- Terraform `>= 1.10`, Scaleway provider `~> 2.48`
- A Scaleway account with an IAM API key, `jq` for the rebill script
