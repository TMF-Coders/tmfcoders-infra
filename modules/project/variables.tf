variable "project_name" {
  description = "The name of the Scaleway project"
  type        = string
}

variable "description" {
  description = "Description of the project"
  type        = string
  default     = ""
}

variable "ssh_key_fingerprints" {
  description = "List of SSH key fingerprints to add to project"
  type        = list(string)
  default     = []
}

variable "ssh_public_key" {
  description = "SSH public key content (for default key)"
  type        = string
  default     = ""
}
