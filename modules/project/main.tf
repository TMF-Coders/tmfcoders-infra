/**
 * Project Module for Scaleway
 * Creates a Scaleway Project (equivalent to GCP Project)
 */

resource "scaleway_account_project" "project" {
  name       = var.project_name
  description = var.description
}

resource "scaleway_account_ssh_key" "default" {
  count       = length(var.ssh_key_fingerprints) > 0 ? 1 : 0
  name       = "${var.project_name}-default-key"
  public_key = var.ssh_public_key
}
