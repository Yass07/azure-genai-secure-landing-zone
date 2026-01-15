############################################
# NAT for ACI test subnet (egress to pull images)
############################################

resource "azurerm_public_ip" "pip_nat_aci_test" {
  name                = "pip-nat-aci-test-${local.env}"
  location            = local.location
  resource_group_name = azurerm_resource_group.core.name

  allocation_method = "Static"
  sku               = "Standard"

  tags = local.tags
}

resource "azurerm_nat_gateway" "nat_aci_test" {
  name                = "nat-aci-test-${local.env}"
  location            = local.location
  resource_group_name = azurerm_resource_group.core.name

  sku_name                = "Standard"
  idle_timeout_in_minutes = 10

  tags = local.tags
}

resource "azurerm_nat_gateway_public_ip_association" "nat_aci_test_pip" {
  nat_gateway_id       = azurerm_nat_gateway.nat_aci_test.id
  public_ip_address_id = azurerm_public_ip.pip_nat_aci_test.id
}

resource "azurerm_subnet_nat_gateway_association" "aci_test" {
  subnet_id      = azurerm_subnet.aci_test.id
  nat_gateway_id = azurerm_nat_gateway.nat_aci_test.id
}
