############################################
# Azure AI Search (workload step 1)
# - Create Search service (minimal)
# - Send metrics + logs to LAW
############################################

resource "azurerm_search_service" "search" {
  count = var.enable_search ? 1 : 0

  # Имя должно быть уникальным глобально.
  # Держим lowercase и без спецсимволов.
  name                = "srchgenai${local.env}9307"
  resource_group_name = azurerm_resource_group.core.name
  location            = local.location

  sku             = "basic"
  replica_count   = 1
  partition_count = 1

  public_network_access_enabled = false

  tags = local.tags
}

resource "azurerm_monitor_diagnostic_setting" "search_to_law" {
  count                      = var.enable_search ? 1 : 0
  name                       = "diag-search-${local.env}-law"
  target_resource_id         = azurerm_search_service.search[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  # Logs
  enabled_log {
    category = "OperationLogs"
  }

  # Metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
# Send Azure AI Search diagnostics to Log Analytics Workspace
data "azurerm_monitor_diagnostic_categories" "search" {
  count       = var.enable_search ? 1 : 0
  resource_id = azurerm_search_service.search[0].id
}
