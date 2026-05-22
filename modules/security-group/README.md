# Module: security-group

Creates a stateful Scaleway instance security group with a default-deny
inbound policy and explicit allow rules.

## Usage

```hcl
module "security_group_apps" {
  source              = "../modules/security-group"
  security_group_name = "acme-prod-apps"
  description         = "Apps tier"
  project_id          = var.project_id

  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  inbound_rules = [
    { action = "accept", protocol = "TCP", port = 8069, ip_range = "10.10.20.0/24" },
  ]
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
| `scaleway_instance_security_group.this` | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `security_group_name` | Name of the security group | `string` | n/a | yes |
| `description` | Description of the security group | `string` | `""` | no |
| `project_id` | Scaleway project ID | `string` | n/a | yes |
| `inbound_default_policy` | Default inbound policy (`accept` / `drop`) | `string` | `"drop"` | no |
| `outbound_default_policy` | Default outbound policy (`accept` / `drop`) | `string` | `"accept"` | no |
| `inbound_rules` | Inbound rules (`action`,`protocol`,`port`,`port_range`,`ip_range`) | `list(object)` | `[]` | no |
| `outbound_rules` | Outbound rules (same shape) | `list(object)` | `[]` | no |
| `tags` | Tags applied to the security group | `list(string)` | `[]` | no |

### Rule object

| Field | Type | Default |
|-------|------|---------|
| `action` | `string` | `"accept"` |
| `protocol` | `string` | `"TCP"` |
| `port` | `number` | `null` |
| `port_range` | `string` | `null` |
| `ip_range` | `string` | `"0.0.0.0/0"` |

## Outputs

| Name | Description |
|------|-------------|
| `security_group_id` | The security group ID |
| `security_group_name` | The security group name |
<!-- END_TF_DOCS -->
