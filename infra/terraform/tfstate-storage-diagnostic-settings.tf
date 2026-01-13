# Send tfstate Storage Account diagnostics to Log Analytics Workspace

data "azurerm_storage_account" "tfstate" {
  name                = "sttfstategenai9307"
  resource_group_name = "rg-tfstate-genai-dev"
}

data "azurerm_monitor_diagnostic_categories" "tfstate_sa" {
  resource_id = data.azurerm_storage_account.tfstate.id
}

resource "azurerm_monitor_diagnostic_setting" "tfstate_sa_to_law" {
  name                       = "diag-tfstate-sa-${local.env}-law"
  target_resource_id         = data.azurerm_storage_account.tfstate.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  metric {
    category = "Transaction"
    enabled  = true
  }

  metric {
    category = "Capacity"
    enabled  = true
  }
}
