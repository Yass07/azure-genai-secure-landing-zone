############################################
# Network foundation (minimal, dev)
# - VNet
# - Subnets: workload + private-endpoints
# - NSG per subnet + association
############################################

variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "subnet_workload_prefixes" {
  description = "Workload subnet prefixes"
  type        = list(string)
  default     = ["10.10.1.0/24"]
}

variable "subnet_private_endpoints_prefixes" {
  description = "Private Endpoints subnet prefixes"
  type        = list(string)
  default     = ["10.10.2.0/24"]
}

resource "azurerm_virtual_network" "core" {
  name                = "vnet-genai-${local.env}"
  location            = local.location
  resource_group_name = azurerm_resource_group.core.name
  address_space       = var.vnet_address_space
  tags                = local.tags
}

resource "azurerm_subnet" "workload" {
  name                 = "snet-workload-${local.env}"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = var.subnet_workload_prefixes
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints-${local.env}"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = var.subnet_private_endpoints_prefixes

  # Required for Private Endpoints in this subnet
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_network_security_group" "workload" {
  name                = "nsg-workload-${local.env}"
  location            = local.location
  resource_group_name = azurerm_resource_group.core.name
  tags                = local.tags
}

resource "azurerm_network_security_group" "private_endpoints" {
  name                = "nsg-private-endpoints-${local.env}"
  location            = local.location
  resource_group_name = azurerm_resource_group.core.name
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "workload" {
  subnet_id                 = azurerm_subnet.workload.id
  network_security_group_id = azurerm_network_security_group.workload.id
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}
