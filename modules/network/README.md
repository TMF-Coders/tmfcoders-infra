# Module: network

Creates a Scaleway VPC v2, one private network per entry in `private_networks`
(each with its own IPv4 subnet), and an optional Public Gateway providing NAT
egress plus an SSH bastion. No workload is exposed directly to the internet.

## Usage

```hcl
module "network" {
  source      = "../modules/network"
  name_prefix = "acme-prod"
  project_id  = var.project_id
  region      = "fr-par"
  zone        = "fr-par-1"

  private_networks = {
    tmf  = { subnet = "10.10.10.0/24" }
    apps = { subnet = "10.10.20.0/24" }
  }

  enable_public_gateway = true
  bastion_enabled       = true
  bastion_port          = 61000
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
| `scaleway_vpc.this` | resource | always |
| `scaleway_vpc_private_network.this` | resource | one per `private_networks` entry |
| `scaleway_vpc_public_gateway_ip.this` | resource | `enable_public_gateway = true` |
| `scaleway_vpc_public_gateway.this` | resource | `enable_public_gateway = true` |
| `scaleway_vpc_gateway_network.this` | resource | one per PN when gateway enabled |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name_prefix` | Prefix applied to all network resource names | `string` | n/a | yes |
| `project_id` | Scaleway project ID | `string` | n/a | yes |
| `region` | Scaleway region (EU only: fr-par, nl-ams, pl-waw) | `string` | `"fr-par"` | no |
| `zone` | Scaleway zone for the public gateway | `string` | `"fr-par-1"` | no |
| `private_networks` | Map of private networks to create (key = short name, value = `{subnet}` CIDR) | `map(object({subnet=string}))` | n/a | yes |
| `enable_public_gateway` | Create a Public Gateway for NAT egress + bastion | `bool` | `true` | no |
| `public_gateway_type` | Public Gateway commercial type | `string` | `"VPC-GW-S"` | no |
| `bastion_enabled` | Enable the SSH bastion on the gateway | `bool` | `true` | no |
| `bastion_port` | TCP port exposed by the SSH bastion | `number` | `61000` | no |
| `tags` | Tags applied to network resources | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | The VPC ID |
| `private_network_ids` | Map of private network short name to ID |
| `private_network_subnets` | Map of private network short name to subnet CIDR |
| `public_gateway_id` | Public Gateway ID (null if disabled) |
| `public_gateway_ip` | Public Gateway public IP (null if disabled) |
| `bastion_port` | SSH bastion port (null if gateway/bastion disabled) |
<!-- END_TF_DOCS -->
