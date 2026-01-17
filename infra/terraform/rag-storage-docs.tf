############################################
# RAG - Documents Storage (Blob, private-by-default)
# Purpose:
# - Store documents for indexing in Azure AI Search
# - Keep data plane private via Private Endpoint + Private DNS
# - Send basic metrics to Log Analytics (metrics-only)
############################################

resource "azurerm_storage_account" "rag_docs" {
  name                = "stgenaidocs${local.env}9307"
  resource_group_name = azurerm_resource_group.core.name
  location            = local.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Security baseline
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false

  tags = local.tags
}

# Container (ARM/management-plane) to avoid Blob data-plane access from local machine
# IMPORTANT: parent_id must be blobServices resource id: .../blobServices/default
resource "azapi_resource" "rag_docs_container" {
  type      = "Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01"
  name      = "docs"
  parent_id = "${azurerm_storage_account.rag_docs.id}/blobServices/default"

  body = jsonencode({
    properties = {
      publicAccess = "None"
    }
  })
}

resource "azurerm_private_endpoint" "rag_docs_blob" {
  name                = "pe-st-docs-${local.env}"
  resource_group_name = azurerm_resource_group.core.name
  location            = local.location
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-st-docs-${local.env}"
    private_connection_resource_id = azurerm_storage_account.rag_docs.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "pdzg-st-docs-${local.env}"
    private_dns_zone_ids = [azurerm_private_dns_zone.core["blob"].id]
  }

  tags = local.tags
}

resource "azurerm_monitor_diagnostic_setting" "rag_docs_sa_to_law" {
  name                       = "diag-st-docs-${local.env}-law"
  target_resource_id         = azurerm_storage_account.rag_docs.id
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
