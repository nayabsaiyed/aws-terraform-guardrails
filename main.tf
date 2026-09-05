provider "aws" {
  region              = var.region
  allowed_account_ids = [split(":", var.github_oidc_provider_arn)[4]]

  default_tags {
    tags = {
      Project   = var.name
      ManagedBy = "Terraform"
      Purpose   = "Guardrails demonstration"
    }
  }
}

locals {
  # New GitHub repositories use immutable IDs in their subject. Older repos
  # can omit both IDs only after verifying they still use the classic format.
  repository_subject = var.github_repository.owner_id == null ? "${var.github_repository.owner}/${var.github_repository.name}" : "${var.github_repository.owner}@${var.github_repository.owner_id}/${var.github_repository.name}@${coalesce(var.github_repository.repository_id, "invalid")}"
  oidc_subject       = "repo:${local.repository_subject}:environment:${var.github_environment}"
}
