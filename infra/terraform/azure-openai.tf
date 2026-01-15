resource "azurerm_cognitive_account" "openai" {
  name                = "oai-genai-${local.env}-9307"
  location            = local.location
  resource_group_name = azurerm_resource_group.core.name

  kind     = "OpenAI"
  sku_name = "S0"

  # Важно для ряда сценариев Azure AI services, включая сетевые (immutable).
  custom_subdomain_name = "oai-genai-${local.env}-9307"

  # Private-by-default
  public_network_access_enabled = false

  tags = local.tags
}
