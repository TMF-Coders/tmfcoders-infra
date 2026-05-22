/**
 * Scheduler Module - Scaleway
 * Powers a set of instances off and on at fixed times to save compute cost
 * (a stopped instance is not billed for compute). Implemented as a Serverless
 * Function driven by two crons.
 *
 * Cron schedules are UTC. The defaults map to 01:00-09:00 CET (UTC+1);
 * during CEST (summer, UTC+2) the window shifts one hour - adjust the cron
 * variables if exact local times are required year-round.
 */

data "archive_file" "function" {
  type        = "zip"
  source_dir  = "${path.module}/function"
  output_path = "${path.module}/function.zip"
}

resource "scaleway_function_namespace" "this" {
  name        = "${var.name_prefix}-scheduler"
  description = "VM power scheduler"
  project_id  = var.project_id
  region      = var.region
}

resource "scaleway_function" "power" {
  name         = "${var.name_prefix}-vm-power"
  namespace_id = scaleway_function_namespace.this.id
  region       = var.region
  runtime      = "python311"
  handler      = "handler.handle"
  privacy      = "private"
  zip_file     = data.archive_file.function.output_path
  zip_hash     = data.archive_file.function.output_sha256
  deploy       = true
  min_scale    = 0
  max_scale    = 1
  memory_limit = 256

  environment_variables = {
    SCW_ZONE   = var.zone
    SERVER_IDS = join(",", var.server_ids)
  }

  secret_environment_variables = {
    SCW_SECRET_KEY = var.scw_secret_key
  }
}

# Power OFF (default 01:00 CET = 00:00 UTC)
resource "scaleway_function_cron" "power_off" {
  function_id = scaleway_function.power.id
  region      = var.region
  schedule    = var.power_off_cron
  args        = jsonencode({ action = "poweroff" })
}

# Power ON (default 09:00 CET = 08:00 UTC)
resource "scaleway_function_cron" "power_on" {
  function_id = scaleway_function.power.id
  region      = var.region
  schedule    = var.power_on_cron
  args        = jsonencode({ action = "poweron" })
}
