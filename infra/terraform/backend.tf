terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-genai-dev"
    storage_account_name = "sttfstategenai9307"
    container_name       = "tfstate"
    key                  = "dev/infra.terraform.tfstate"
  }
}