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

  # Для будущего Private Endpoint Free tier не подходит.
  # Microsoft Learn: private endpoints не поддерживаются на Free, нужен Basic или выше.
  sku             = "basic"
  replica_count   = 1
  partition_count = 1

  tags = local.tags
}

data "azurerm_monitor_diagnostic_categories" "search" {
  resource_id = azurerm_search_service.search.id
}

resource "azurerm_monitor_diagnostic_setting" "search_to_law" {
  name                       = "diag-search-${local.env}-law"
  target_resource_id         = azurerm_search_service.search.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  # Logs
  dynamic "enabled_log" {
    for_each = toset(data.azurerm_monitor_diagnostic_categories.search.logs)
    content {
      category = enabled_log.value
    }
  }

  # Metrics
  dynamic "metric" {
    for_each = toset(data.azurerm_monitor_diagnostic_categories.search.metrics)
    content {
      category = metric.value
      enabled  = true
    }
  }
}
