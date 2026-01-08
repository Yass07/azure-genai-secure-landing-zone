locals {
  project = "azure-genai-secure-landing-zone"
  env     = "dev"
  location = "westeurope"

  tags = {
    project = local.project
    env     = local.env
    owner   = "ig"
    managed_by = "terraform"
  }
}

# Intentionally empty for now.
# Resources will be added step-by-step after:
# - backend strategy is decided
# - auth method is decided (OIDC vs SPN vs interactive)
# - naming convention is agreed
