############################################
# TEMP: ACI egress (NAT Gateway) for image pull / apk
# Scope: only snet-aci-test-${local.env}
# Note: remove later after checks are done
############################################

resource "azurerm_public_ip" "aci_nat_pip" {
  name                = "pip-aci-egress-${local.env}"
  location            = local.location
  resource_group_name = azurerm_resource_group.core.name

  allocation_method = "Static"
  sku               = "Standard"

  tags = local.tags
}

resource "azurerm_nat_gateway" "aci_nat" {
  name                = "natgw-aci-egress-${local.env}"
  location            = local.location
  resource_group_name = azurerm_resource_group.core.name

  sku_name                = "Standard"
  idle_timeout_in_minutes = 10

  tags = local.tags
}

resource "azurerm_nat_gateway_public_ip_association" "aci_nat_pip" {
  nat_gateway_id       = azurerm_nat_gateway.aci_nat.id
  public_ip_address_id = azurerm_public_ip.aci_nat_pip.id
}

resource "azurerm_subnet_nat_gateway_association" "aci_test" {
  subnet_id      = azurerm_subnet.aci_test.id
  nat_gateway_id = azurerm_nat_gateway.aci_nat.id
}
