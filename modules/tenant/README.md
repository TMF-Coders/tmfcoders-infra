# Module: tenant

Provisions one isolated Scaleway Project for a Project-mode tenant inside the
home Organization. A Project is Scaleway's unit of billing segregation, so each
tenant Project yields a clean per-tenant cost breakdown.

Optionally creates a scoped IAM application giving the client read-only access
to their own Project (delegated visibility, never cross-tenant).

## Usage

```hcl
module "tenant_acme" {
  source       = "../modules/tenant"
  tenant       = "acme"
  project_name = "client-acme-prod"
  description  = "ACME - production"

  create_client_access   = true
  client_permission_sets = ["ProjectReadOnly", "BillingReadOnly"]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10 |
| scaleway | ~> 2.48 |

## Resources

| Name | Type | Created when |
|------|------|--------------|
| `scaleway_account_project.this` | resource | always |
| `scaleway_iam_application.client` | resource | `create_client_access = true` |
| `scaleway_iam_policy.client` | resource | `create_client_access = true` |
| `scaleway_iam_api_key.client` | resource | `create_client_access = true` |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `tenant` | Tenant short name | `string` | n/a | yes |
| `project_name` | Name of the Scaleway project for this tenant/environment | `string` | n/a | yes |
| `description` | Project description | `string` | `""` | no |
| `create_client_access` | Create a scoped IAM application giving the client access to their own project | `bool` | `false` | no |
| `client_permission_sets` | Permission sets granted to the client IAM application | `list(string)` | `["ProjectReadOnly","BillingReadOnly"]` | no |

## Outputs

| Name | Description |
|------|-------------|
| `project_id` | The tenant's Scaleway project ID |
| `project_name` | The tenant's Scaleway project name |
| `client_access_key` | Client IAM access key (null when client access disabled) |
| `client_secret_key` | Client IAM secret key, sensitive (null when disabled) |
<!-- END_TF_DOCS -->
