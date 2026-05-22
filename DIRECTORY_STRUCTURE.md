# Directory Structure - TMF Coders Infrastructure

```
tmfcoders-infra/
│
├── 0-bootstrap/                Landing zone (run once per Organization)
│   ├── *.tf                      state bucket, CI IAM, platform project
│   ├── backend.hcl.example       remote backend template (post-migration)
│   └── terraform.tfvars.example  fill in -> terraform.tfvars (gitignored)
│
├── tenant-provisioning/        Creates Project-mode tenant projects
│   ├── *.tf                      for_each over var.tenant_projects
│   ├── backend.hcl
│   └── terraform.tfvars.example
│
├── 1-org/                      LAYER (canonical) - security, IAM, secrets
│   ├── main.tf                   security groups
│   ├── iam.tf                    workload IAM applications
│   ├── secrets.tf                Secret Manager
│   └── {variables,outputs,providers,versions}.tf
│
├── 2-network/                  LAYER - VPC v2, private networks, gateway
│   └── *.tf
│
├── 3-apps/                     LAYER - VMs, Managed PostgreSQL, Load Balancer
│   ├── *.tf
│   └── templates/                cloud-init scripts (.tftpl)
│
├── 4-observability/            LAYER - Cockpit, immutable audit archive
│   └── *.tf
│
├── modules/                    Reusable modules
│   ├── project/                  Scaleway project
│   ├── tenant/                   tenant project + scoped client IAM
│   ├── network/                  VPC v2 + private networks + gateway
│   ├── instance/                 hardened compute instance
│   └── security-group/           stateful firewall
│
├── tenants/                    Per-tenant deployment configs
│   ├── _template/prod/           placeholder backend.hcl + .tfvars (x4 layers)
│   ├── tmf-internal/prod/        internal workloads (Project-mode)
│   ├── acme/prod/                example client (Project-mode)
│   └── bigbank/prod/             example client (Org-mode)
│       └── <layer>.backend.hcl   state key for (tenant, env, layer)
│       └── <layer>.tfvars        variable values for (tenant, env, layer)
│
├── scripts/
│   ├── new-tenant.sh             scaffold a tenant from _template
│   └── rebill.sh                 monthly per-tenant cost report (Billing API)
│
├── docs/
│   ├── BILLING.md                cost segmentation & rebilling
│   ├── IAM.md                    identities, policies, permission sets
│   ├── NETWORKING.md             topology, address plan, bastion
│   ├── SECURITY.md               controls, threat model, hardening
│   ├── OBSERVABILITY.md          Cockpit, audit archive, alerting
│   └── DISASTER_RECOVERY.md      RPO/RTO, restore procedures
│
├── .github/workflows/
│   └── terraform-ci.yml          quality gate (fmt, lint, tfsec, checkov...)
│
├── .tflint.hcl  .tfsec.yml  .gitleaks.toml  .pre-commit-config.yaml
├── Makefile                    layer/tenant operations
├── init.sh                     prerequisites + tfvars scaffolding
│
├── README.md                   overview + quick start
├── ARCHITECTURE.md             tenancy model, layers, security
├── RUNBOOK.md                  step-by-step operations
├── QUICK_START.md              fastest path to a running tenant
├── CONTRIBUTING.md             workflow & conventions
└── DIRECTORY_STRUCTURE.md      this file
```

## Layout rules

- A **layer** (`1-org`..`4-observability`) is a single canonical Terraform root.
  A deployment is a *(tenant, environment)* pair — selected at `init`/`apply`
  time via `tenants/<tenant>/<env>/<layer>.{backend.hcl,tfvars}`.
- **State keys** are tenant-scoped: `tenants/<t>/<layer>/<env>/terraform.tfstate`.
- **Modules** hold reusable resources; layers only wire modules together.
- Tenant `.tfvars` ARE committed (no secrets). `terraform.tfvars` for the
  shared roots, `.terraform/` and state files are gitignored.
- `.terraform.lock.hcl` IS committed (provider pinning).
