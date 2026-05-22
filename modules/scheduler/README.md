# Module: scheduler

Powers a set of Scaleway instances off and on at fixed times to save compute
cost — a stopped instance is not billed for compute. Implemented as a
Serverless Function (Python, standard library only) driven by two crons.

The default schedule powers instances **off at 01:00 CET** and **on at 09:00
CET**. Cron expressions are UTC; defaults assume CET (UTC+1). During CEST
(summer) the window shifts one hour — override the cron variables for exact
year-round local times.

## Usage

```hcl
module "scheduler" {
  source         = "../modules/scheduler"
  name_prefix    = "acme-prod"
  project_id     = var.project_id
  region         = var.region
  zone           = var.zone
  server_ids     = [module.odoo.instance_id, module.openclaw.instance_id]
  scw_secret_key = data.terraform_remote_state.org.outputs.scheduler_workload_secret_key
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10 |
| scaleway | ~> 2.48 |
| archive | ~> 2.4 |

## Resources

| Name | Type |
|------|------|
| `scaleway_function_namespace.this` | resource |
| `scaleway_function.power` | resource |
| `scaleway_function_cron.power_off` | resource |
| `scaleway_function_cron.power_on` | resource |
| `archive_file.function` | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name_prefix` | Prefix for scheduler resource names | `string` | n/a | yes |
| `project_id` | Scaleway project ID | `string` | n/a | yes |
| `region` | Scaleway region | `string` | `"fr-par"` | no |
| `zone` | Zone of the target instances | `string` | `"fr-par-1"` | no |
| `server_ids` | Instance IDs to power off/on | `list(string)` | n/a | yes |
| `scw_secret_key` | API secret key with Instances power permissions (sensitive) | `string` | n/a | yes |
| `power_off_cron` | UTC cron for power off (default 01:00 CET) | `string` | `"0 0 * * *"` | no |
| `power_on_cron` | UTC cron for power on (default 09:00 CET) | `string` | `"0 8 * * *"` | no |

## Outputs

| Name | Description |
|------|-------------|
| `namespace_id` | Serverless Function namespace ID |
| `function_id` | VM power scheduler function ID |
| `power_off_cron` / `power_on_cron` | Active cron schedules (UTC) |
<!-- END_TF_DOCS -->
