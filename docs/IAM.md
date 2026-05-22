# IAM Matrix - TMF Coders Infrastructure

Scaleway IAM model: every non-human actor is an **IAM application** with a
least-privilege **policy** and its own **API key**. No personal user keys are
used for automation.

## Identities

| Identity | Layer | Scope | Purpose |
|----------|-------|-------|---------|
| `tmfcoders-terraform-ci` | `0-bootstrap` | Organization-wide | GitHub Actions Terraform pipeline |
| `<tenant>-<env>-odoo` | `1-org` | Tenant project | Odoo workload — read secrets, write observability |
| `<tenant>-<env>-openclaw` | `1-org` | Tenant project | OpenClaw workload — read secrets, write observability |
| `<project>-client-access` | `tenant-provisioning` | Tenant project | Optional delegated client read-only access |

## Policies / permission sets

### CI pipeline (`0-bootstrap`)

Organization-wide — the pipeline must deploy into every tenant project:

```
InstancesFullAccess        PrivateNetworksReadWrite   VPCFullAccess
ObjectStorageFullAccess    SecretManagerFullAccess    RelationalDatabasesFullAccess
LoadBalancersFullAccess    ObservabilityFullAccess    ProjectManager
IAMManager
```

### Workload identities (`1-org`)

Scoped to the tenant's own project only:

```
SecretManagerSecretAccess   ObservabilityFullAccess
```

The workload key is the minimal credential a VM needs at boot to pull its
secrets from Secret Manager. Even if leaked from state it only reads that
tenant's secrets, and it is rotatable.

### Client delegated access (`modules/tenant`)

Scoped to the tenant's own project, default read-only:

```
ProjectReadOnly   BillingReadOnly
```

## API keys

| Key | Stored in | Consumed by |
|-----|-----------|-------------|
| CI key | GitHub repo secrets (`SCW_ACCESS_KEY` / `SCW_SECRET_KEY`) | CI pipeline |
| Workload keys | Terraform state (sensitive output) → injected into VM cloud-init | Odoo / OpenClaw VMs |
| Client keys | Handed to the client out-of-band | Client console / API |

## Rotation

- **CI key**: recreate `scaleway_iam_api_key.terraform_ci` (taint + apply),
  update the GitHub secrets.
- **Workload keys**: recreate the `scaleway_iam_api_key` in `1-org`,
  re-apply `3-apps` so cloud-init receives the new value.
- Quarterly rotation recommended.

## Org-mode tenants

Each Org-mode tenant Organization has its own IAM root. Run `0-bootstrap`
there to create a dedicated CI identity; TMF Coders operates via a delegated
IAM membership granted by the client.

## Boundaries

- No cross-tenant access: workload and client policies are project-scoped.
- No personal keys in automation.
- `IAMManager` on the CI identity is required to manage workload IAM apps;
  review CI key custody accordingly.
