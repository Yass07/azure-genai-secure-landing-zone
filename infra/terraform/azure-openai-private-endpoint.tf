resource "azurerm_private_endpoint" "openai" {
  name                = "pe-openai-${local.env}"
  location            = local.location
  resource_group_name = azurerm_resource_group.core.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-openai-${local.env}"
    private_connection_resource_id = azurerm_cognitive_account.openai.id

    # group_id для Cognitive Services Private Link.
    subresource_names    = ["account"]
    is_manual_connection = false
  }

  private_dns_zone_group {
    name                 = "pdzg-openai-${local.env}"
    private_dns_zone_ids = [azurerm_private_dns_zone.core["openai"].id]
  }
}
