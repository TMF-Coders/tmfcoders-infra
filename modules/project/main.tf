/**
 * Project Module - Scaleway
 * Creates an isolated Scaleway Project for resource + cost segregation.
 * Equivalent to a GCP project. SSH keys are registered at organization
 * level via scaleway_iam_ssh_key (project-scoped key injection).
 */

resource "scaleway_account_project" "this" {
  name        = var.project_name
  description = var.description
}

resource "scaleway_iam_ssh_key" "this" {
  for_each = var.ssh_public_keys

  name       = "${var.project_name}-${each.key}"
  public_key = each.value
  project_id = scaleway_account_project.this.id
}
