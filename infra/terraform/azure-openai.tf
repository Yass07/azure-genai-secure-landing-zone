############################################
# Azure OpenAI (Cognitive Account - kind OpenAI)
############################################

resource "azurerm_cognitive_account" "openai" {
  name                = "oaigenai${local.env}9307"
  location            = local.location
  resource_group_name = azurerm_resource_group.core.name

  kind     = "OpenAI"
  sku_name = "S0"

  public_network_access_enabled = false

  tags = local.tags
}
