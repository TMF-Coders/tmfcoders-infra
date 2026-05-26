bucket   = "tmfcoders-terraform-state-CHANGEME"
key      = "tenants/acme/4-observability/prod/terraform.tfstate"
region   = "fr-par"
endpoints = { s3 = "https://s3.fr-par.scw.cloud" }

skip_credentials_validation = true
skip_region_validation      = true
skip_requesting_account_id  = true
skip_s3_checksum            = true
use_lockfile                = true
