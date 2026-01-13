# Send Key Vault diagnostics to Log Analytics Workspace

data "azurerm_monitor_diagnostic_categories" "kv" {
  resource_id = azurerm_key_vault.kv.id
}

resource "azurerm_monitor_diagnostic_setting" "kv_to_law" {
  name                       = "diag-kv-${local.env}-law"
  target_resource_id         = azurerm_key_vault.kv.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
