# Architecture - TMF Coders Infrastructure

Bank-grade, multi-tenant Infrastructure as Code on **Scaleway** (EU cloud,
GDPR-by-design). Terraform, layered, with per-tenant billing segmentation.

## Tenancy model (hybrid)

| Tenant kind | Lives in | `billing_mode` | Pays Scaleway |
|-------------|----------|----------------|---------------|
| Landing zone / platform | Platform Project, home Org | n/a (`billable:false`) | TMF Coders |
| Internal workloads | Project in home Org | `project` | TMF Coders |
| Small / temporary client | Project in home Org | `project` | TMF Coders, rebills |
| Client as legal entity | Its own Organization | `org` | The client directly |

- Scaleway issues one **invoice per Organization** and reports **consumption
  per Project**. A Project per tenant gives a native cost breakdown.
- **Project-mode**: tenant Project in the home Org, created by
  `tenant-provisioning`. TMF Coders pays the Org invoice and rebills.
- **Org-mode**: client owns a separate Organization; run `0-bootstrap` against
  it. Client is invoiced directly by Scaleway; TMF Coders operates via
  delegated IAM. See [docs/BILLING.md](docs/BILLING.md).

## Layered model

| Layer | Scope | State key |
|-------|-------|-----------|
| `0-bootstrap` | per Organization | `0-bootstrap/terraform.tfstate` |
| `tenant-provisioning` | home Organization | `landing-zone/tenant-provisioning/...` |
| `1-org` | per tenant/env | `tenants/<t>/1-org/<env>/terraform.tfstate` |
| `2-network` | per tenant/env | `tenants/<t>/2-network/<env>/terraform.tfstate` |
| `3-apps` | per tenant/env | `tenants/<t>/3-apps/<env>/terraform.tfstate` |
| `4-observability` | per tenant/env | `tenants/<t>/4-observability/<env>/...` |

`1-org`..`4-observability` are **single canonical roots**. A deployment is a
*(tenant, environment)* pair, selected at `init`/`apply` time:

```
terraform -chdir=2-network init  -backend-config=tenants/<t>/<env>/2-network.backend.hcl
terraform -chdir=2-network apply -var-file=tenants/<t>/<env>/2-network.tfvars
```

The `Makefile` wraps this as `make tenant-apply TENANT=<t> ENV=<env> LAYER=<l>`.
Cross-layer values flow through `terraform_remote_state`, tenant-scoped by key.

## Network topology (per tenant)

```
Tenant Project
└── VPC: <tenant>-<env>-vpc  (regional, fr-par)
    ├── PN tmf   10.10.10.0/24   → OpenClaw VM (Matriz)
    ├── PN apps  10.10.20.0/24   → Odoo VM (Filial) + Managed PostgreSQL
    └── Public Gateway  <tenant>-<env>-gateway
        ├── NAT masquerade + default route (egress for both PNs)
        └── SSH bastion on port 61000 (only public ingress to VMs)

Internet ──HTTPS──> Load Balancer (LB-S) ──http──> Odoo VM :8069
```

Each tenant gets its own VPC and address plan — networks are never shared
across tenants.

## Security model

| Control | Implementation |
|---------|----------------|
| Tenant isolation | One Project (or Organization) per tenant |
| Network firewall | `scaleway_instance_security_group`, default-deny inbound |
| No direct SSH | Public Gateway bastion (`bastion_enabled = true`) |
| No public VM IPs | `assign_public_ip = false` by default |
| Workload identity | One IAM application + scoped policy per workload |
| CI identity | Org-wide IAM application, dedicated key per Organization |
| Client access | Optional scoped read-only IAM app per tenant Project |
| Secrets | `scaleway_secret` — generated passwords, never in tfvars |
| State protection | Private, versioned bucket; `use_lockfile` locking; per-tenant keys |
| Audit immutability | Object Lock (COMPLIANCE, 730 days) on the audit bucket |
| Data residency | EU regions only, enforced by variable validation |

## Observability (3 pillars, per tenant)

1. **Logs & metrics** — Scaleway Cockpit (managed Grafana + Loki + Mimir).
2. **Immutable audit archive** — Object Storage with Object Lock (COMPLIANCE,
   730-day GDPR retention).
3. **Alerting** — Cockpit Alert Manager with an email contact point.

## Billing segmentation

Every resource is tagged `tenant`, `cost-center`, `billing-mode`, `billable`
and `environment`. The landing zone is `billable:false` (shared overhead).
`scripts/rebill.sh` queries the Billing API, groups consumption by Project and
applies a markup for client invoicing.

## Conventions

- Naming: `<tenant>-<env>-<workload>[-NNN]`.
- Terraform `>= 1.10`, provider `scaleway ~> 2.48`.
- Tenant `.tfvars` are committed (no secrets); `terraform.tfvars` for the
  shared roots and all state files are never committed.
