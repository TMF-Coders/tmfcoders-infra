# Layer: 0-bootstrap (Landing Zone)

Foundation layer. Run **once per Scaleway Organization**.

## Purpose

- Creates the platform (landing-zone) Project — shared, `billable:false`.
- Creates the Object Storage bucket that holds all remote Terraform state.
- Creates the CI/CD IAM application with an Organization-wide policy and an
  API key for the GitHub Actions pipeline.

This is a chicken-and-egg layer: it creates the state bucket, so it runs on
**local state** first, then migrates into the bucket it just created.

## Dependencies

None. This is the first layer.

## Deploy

```bash
# edit terraform.tfvars (state_bucket_suffix must be globally unique)
terraform -chdir=0-bootstrap init
terraform -chdir=0-bootstrap apply

# copy state_bucket_name into every backend.hcl, then migrate:
terraform -chdir=0-bootstrap init -migrate-state -backend-config=backend.hcl
```

Makefile: `make bootstrap-apply`, `make bootstrap-migrate`.

For **Org-mode** tenants, run this layer again with that Organization's
credentials and its own state bucket.

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| `project_name` | Platform project name | `"TMF Coders - Platform"` |
| `region` | EU region | `"fr-par"` |
| `zone` | Zone | `"fr-par-1"` |
| `state_bucket_name` | Base name of the state bucket | `"tmfcoders-terraform-state"` |
| `state_bucket_suffix` | Globally-unique suffix (3-20 lowercase alnum) | n/a (required) |

## Outputs

| Name | Description |
|------|-------------|
| `project_id` | Platform project ID |
| `organization_id` | Scaleway organization ID |
| `state_bucket_name` | State bucket name — use in every `backend.hcl` |
| `state_bucket_endpoint` | S3-compatible endpoint |
| `terraform_ci_application_id` | CI IAM application ID |
| `terraform_ci_access_key` | CI access key → `SCW_ACCESS_KEY` GitHub secret (sensitive) |
| `terraform_ci_secret_key` | CI secret key → `SCW_SECRET_KEY` GitHub secret (sensitive) |
