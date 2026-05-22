variable "project_name" {
  description = "Name of the Scaleway project"
  type        = string

  validation {
    condition     = length(var.project_name) >= 3 && length(var.project_name) <= 100
    error_message = "project_name must be between 3 and 100 characters."
  }
}

variable "description" {
  description = "Description of the project"
  type        = string
  default     = ""
}

variable "ssh_public_keys" {
  description = "Map of named SSH public keys to register on the project (key = name suffix, value = public key material)"
  type        = map(string)
  default     = {}
}
