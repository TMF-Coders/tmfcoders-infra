bucket   = "__BUCKET__"
key      = "tenants/__TENANT__/1-org/__ENV__/terraform.tfstate"
region   = "fr-par"
endpoint = "s3.fr-par.scw.cloud"

skip_credentials_validation = true
skip_region_validation      = true
skip_requesting_account_id  = true
skip_s3_checksum            = true
use_lockfile                = true
