############################################
# Azure AI Search (workload step 1)
# - Create Search service (minimal)
# - Send metrics + logs to LAW
############################################

resource "azurerm_search_service" "search" {
  # Имя должно быть уникальным глобально.
  # Держим lowercase и без спецсимволов.
  name                = "srchgenai${local.env}9307"
  resource_group_name = azurerm_resource_group.core.name
  location            = local.location

  sku             = "basic"
  replica_count   = 1
  partition_count = 1

  tags = local.tags
}

resource "azurerm_monitor_diagnostic_setting" "search_to_law" {
  name                       = "diag-search-${local.env}-law"
  target_resource_id         = azurerm_search_service.search.id
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
