############################################
# Azure AI Search - Private Endpoint (step 3)
# - Private Endpoint in snet-private-endpoints-dev
# - Private DNS zone group for privatelink.search.windows.net
############################################

resource "azurerm_private_endpoint" "search" {
  count               = var.enable_search ? 1 : 0
  name                = "pe-search-${local.env}"
  resource_group_name = azurerm_resource_group.core.name
  location            = local.location
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-search-${local.env}"
    private_connection_resource_id = azurerm_search_service.search[0].id
    is_manual_connection           = false
    subresource_names              = ["searchService"]
  }

  private_dns_zone_group {
    name                 = "pdzg-search-${local.env}"
    private_dns_zone_ids = [azurerm_private_dns_zone.core["search"].id]
  }

  tags = local.tags
}
