data "azurerm_monitor_diagnostic_categories" "openai" {
  resource_id = azurerm_cognitive_account.openai.id
}

resource "azurerm_monitor_diagnostic_setting" "openai_to_law" {
  name                       = "diag-openai-${local.env}-law"
  target_resource_id         = azurerm_cognitive_account.openai.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  dynamic "enabled_log" {
    for_each = toset(data.azurerm_monitor_diagnostic_categories.openai.log_category_types)
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = toset(data.azurerm_monitor_diagnostic_categories.openai.metrics)
    content {
      category = metric.value
      enabled  = true
    }
  }
}
