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

resource "azurerm_log_analytics_workspace" "law" {
  name                = "log-${local.project}-${local.env}"
  location            = local.location
  resource_group_name = azurerm_resource_group.core.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_key_vault" "kv" {
  name                = "kvgenai${local.env}9307"
  location            = local.location
  resource_group_name = azurerm_resource_group.core.name

  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name  = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  enable_rbac_authorization = true

  tags = local.tags
}

data "azurerm_client_config" "current" {}

# Intentionally empty for now.
# Resources will be added step-by-step after:
# - backend strategy is decided
# - auth method is decided (OIDC vs SPN vs interactive)
# - naming convention is agreed
