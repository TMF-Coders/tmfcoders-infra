# Module: instance

Hardened Scaleway compute instance: private-network-only by default,
encrypted block storage, cloud-init bootstrap. A public IP is created only
when `assign_public_ip = true` (production workloads sit behind a Load Balancer).

The boot image is resolved from a marketplace label via a data source, so no
region-specific UUID is hard-coded. `user_data` and `image` are under
`ignore_changes` to prevent unwanted replacement on re-runs.

## Usage

```hcl
module "odoo" {
  source              = "../modules/instance"
  instance_name       = "acme-prod-odoo-001"
  instance_type       = "PRO2-M"
  image_label         = "ubuntu_jammy"
  project_id          = var.project_id
  security_group_id   = data.terraform_remote_state.org.outputs.security_group_apps_id
  private_network_ids = [data.terraform_remote_state.network.outputs.apps_network_id]
  root_volume_size    = 40
  cloud_init          = file("cloud-init.sh")
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
| `scaleway_instance_server.this` | resource | always |
| `scaleway_instance_ip.this` | resource | `assign_public_ip = true` |
| `scaleway_marketplace_image.this` | data source | always |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `instance_name` | Instance name (lowercase, RFC1035-style) | `string` | n/a | yes |
| `instance_type` | Scaleway commercial instance type | `string` | `"PRO2-S"` | no |
| `image_label` | Marketplace image label | `string` | `"ubuntu_noble"` | no |
| `zone` | Scaleway zone | `string` | `"fr-par-1"` | no |
| `project_id` | Scaleway project ID | `string` | n/a | yes |
| `security_group_id` | Security group applied to the instance | `string` | n/a | yes |
| `tags` | Tags for the instance | `list(string)` | `[]` | no |
| `root_volume_size` | Root volume size in GB (10-1000) | `number` | `20` | no |
| `root_volume_type` | Root volume type (sbs_volume, b_ssd, l_ssd) | `string` | `"sbs_volume"` | no |
| `additional_volume_ids` | Additional block volume IDs to attach | `list(string)` | `[]` | no |
| `private_network_ids` | Private network IDs to attach | `list(string)` | `[]` | no |
| `assign_public_ip` | Attach a routed public IP (discouraged in prod) | `bool` | `false` | no |
| `cloud_init` | cloud-init user data script | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| `instance_id` | The instance ID |
| `instance_name` | The instance name |
| `private_ips` | List of IPAM-managed private IPs |
| `private_ip` | First private IP address (null if none) |
| `public_ip` | Public IP (null when private-network-only) |
<!-- END_TF_DOCS -->
