variable "project_name" {
  description = "Name of the platform (landing-zone) Scaleway project"
  type        = string
  default     = "TMF Coders - Platform"
}

variable "region" {
  description = "Scaleway region (EU only for data residency)"
  type        = string
  default     = "fr-par"

  validation {
    condition     = contains(["fr-par", "nl-ams", "pl-waw"], var.region)
    error_message = "region must be an EU region: fr-par, nl-ams or pl-waw."
  }
}

variable "zone" {
  description = "Scaleway default zone"
  type        = string
  default     = "fr-par-1"
}

variable "state_bucket_name" {
  description = "Base name of the Terraform state bucket"
  type        = string
  default     = "tmfcoders-terraform-state"
}

variable "state_bucket_suffix" {
  description = "Globally-unique suffix for the state bucket (Object Storage names are global)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,20}$", var.state_bucket_suffix))
    error_message = "state_bucket_suffix must be 3-20 lowercase alphanumeric characters."
  }
}
