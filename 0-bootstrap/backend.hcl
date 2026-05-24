bucket   = "tmfcoders-terraform-state-a2b56"
key      = "0-bootstrap/terraform.tfstate"
region   = "fr-par"
endpoints = { s3 = "https://s3.fr-par.scw.cloud" }

skip_credentials_validation = true
skip_region_validation      = true
skip_requesting_account_id  = true
skip_s3_checksum            = true
use_lockfile                = true
