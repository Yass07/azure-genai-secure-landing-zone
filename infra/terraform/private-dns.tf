############################################
# Private DNS baseline for future Private Endpoints
# - Create Private DNS zones
# - Link zones to core VNet
############################################

locals {
  private_dns_zones = {
    keyvault = "privatelink.vaultcore.azure.net"
    blob     = "privatelink.blob.core.windows.net"
    search   = "privatelink.search.windows.net"
    openai   = "privatelink.openai.azure.com"
  }
}

resource "azurerm_private_dns_zone" "core" {
  for_each            = local.private_dns_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.core.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "core" {
  for_each              = local.private_dns_zones
  name                  = "vnetlink-${each.key}-${local.env}"
  resource_group_name   = azurerm_resource_group.core.name
  private_dns_zone_name = azurerm_private_dns_zone.core[each.key].name
  virtual_network_id    = azurerm_virtual_network.core.id

  registration_enabled = false
  tags                 = local.tags
}
