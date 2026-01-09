locals {
  project  = "azure-genai-secure-landing-zone"
  env      = var.env
  location = var.location

  tags = {
    project    = local.project
    env        = local.env
    owner      = "ig"
    managed_by = "terraform"
  }
}

resource "azurerm_resource_group" "core" {
  name     = "rg-genai-${local.env}"
  location = local.location
  tags     = local.tags
}

# Intentionally empty for now.
# Resources will be added step-by-step after:
# - backend strategy is decided
# - auth method is decided (OIDC vs SPN vs interactive)
# - naming convention is agreed
