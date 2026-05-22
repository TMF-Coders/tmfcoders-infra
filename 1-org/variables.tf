variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be 'dev' or 'prod'."
  }
}

variable "tenant" {
  description = "Tenant short name - billing/segmentation key"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}$", var.tenant))
    error_message = "tenant must be lowercase alphanumeric with hyphens."
  }
}

variable "cost_center" {
  description = "Cost center for billing attribution / chargeback"
  type        = string
}

variable "billing_mode" {
  description = "Billing model: 'project' (Project in home Org) or 'org' (separate Organization)"
  type        = string
  default     = "project"

  validation {
    condition     = contains(["project", "org"], var.billing_mode)
    error_message = "billing_mode must be 'project' or 'org'."
  }
}

variable "project_id" {
  description = "Scaleway project ID (tenant project)"
  type        = string
}

variable "region" {
  description = "Scaleway region (EU only)"
  type        = string
  default     = "fr-par"

  validation {
    condition     = contains(["fr-par", "nl-ams", "pl-waw"], var.region)
    error_message = "region must be an EU region: fr-par, nl-ams or pl-waw."
  }
}

variable "zone" {
  description = "Scaleway zone"
  type        = string
  default     = "fr-par-1"
}

variable "openclaw_api_key" {
  description = "OpenClaw application API key (optional; leave empty to skip the secret)"
  type        = string
  sensitive   = true
  default     = ""
}
