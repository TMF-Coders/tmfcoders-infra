variable "name_prefix" {
  description = "Prefix applied to scheduler resource names"
  type        = string
}

variable "project_id" {
  description = "Scaleway project ID"
  type        = string
}

variable "region" {
  description = "Scaleway region"
  type        = string
  default     = "fr-par"
}

variable "zone" {
  description = "Scaleway zone of the target instances"
  type        = string
  default     = "fr-par-1"
}

variable "server_ids" {
  description = "Instance IDs to power off/on on schedule"
  type        = list(string)

  validation {
    condition     = length(var.server_ids) > 0
    error_message = "server_ids must list at least one instance."
  }
}

variable "scw_secret_key" {
  description = "Scaleway API secret key with Instances power permissions"
  type        = string
  sensitive   = true
}

variable "power_off_cron" {
  description = "UTC cron expression for powering instances off (default 01:00 CET)"
  type        = string
  default     = "0 0 * * *"
}

variable "power_on_cron" {
  description = "UTC cron expression for powering instances on (default 09:00 CET)"
  type        = string
  default     = "0 8 * * *"
}
