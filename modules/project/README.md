# Module: project

Creates an isolated Scaleway Project and optionally registers SSH keys on it.
A Project is Scaleway's unit of resource and cost segregation (the GCP-project
equivalent).

## Usage

```hcl
module "project" {
  source       = "../modules/project"
  project_name = "TMF Coders - Platform"
  description  = "Shared foundation project"

  ssh_public_keys = {
    ops = "ssh-ed25519 AAAA... ops@tmfcoders"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10 |
| scaleway | ~> 2.48 |

## Resources

| Name | Type |
|------|------|
| `scaleway_account_project.this` | resource |
| `scaleway_iam_ssh_key.this` | resource (one per `ssh_public_keys` entry) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `project_name` | Name of the Scaleway project (3-100 chars) | `string` | n/a | yes |
| `description` | Project description | `string` | `""` | no |
| `ssh_public_keys` | Map of named SSH public keys to register (key = name suffix, value = key material) | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `project_id` | The Scaleway project ID |
| `project_name` | The Scaleway project name |
| `organization_id` | The Scaleway organization ID owning the project |
| `ssh_key_ids` | Map of registered SSH key IDs |
<!-- END_TF_DOCS -->
