# TECH_SNAPSHOT.md — Azure AI Landing Zone (Terraform)

## 0) Статус решения
- Remote state: Azure Blob backend работает, locking работает.
- VS Code Tasks: terraform fmt/validate/plan/show/apply используются регулярно.
- GitHub Actions: workflow plan работает через OIDC без секретов.
- Foundation слои применены: observability baseline, network foundation, private DNS baseline.
- AI workload слой: еще не начат (план на завтра: Azure AI Search).


## 1) Azure Identity (факты)
- Subscription name: Azure-genai-demo
- Subscription ID: 8c1b6b8e-1d06-4753-a963-9868ae05e1d6
- Tenant ID: 8617e3fc-8d68-4e4c-8c72-851745ba64b3
- CLI user: i.jaskelevic@outlook.com


## 2) Azure Resources (фактически существуют)

### 2.1 Resource Groups
- rg-tfstate-genai-dev (westeurope)
- rg-genai-dev (westeurope)

### 2.2 Storage Account (Terraform state)
- Name: sttfstategenai9307
- RG: rg-tfstate-genai-dev
- Location: westeurope
- Kind: StorageV2
- SKU: Standard_LRS

### 2.3 Storage Container
- Container: tfstate
Diagnostic setting на tfstate storage account: категории StorageRead/Write/Delete не поддерживаются. Исправили на metrics-only (Transaction, Capacity)

### 2.4 tfstate blob
- Blob key: dev/infra.terraform.tfstate

    # Terraform state storage
- Storage account: sttfstategenai9307
- Container: tfstate
- Blob key: dev/infra.terraform.tfstate


### 2.5 Log Analytics Workspace
- Name: log-azure-genai-secure-landing-zone-dev
- RG: rg-genai-dev
- Location: westeurope


## 3) Terraform backend (факты)
- Backend type: azurerm
- Backend storage:
  - resource_group_name: rg-tfstate-genai-dev
  - storage_account_name: sttfstategenai9307
  - container_name: tfstate
  - key: dev/infra.terraform.tfstate
- State locking: работает (наблюдалось “Acquiring state lock”)


## 4) Репозиторий — структура (tree)
Путь репозитория:
- C:\Users\ijask_jid\OneDrive\Desktop\Repos\azure-genai-secure-landing-zone

структура:
.azure-genai-secure-landing-zone
├─ .github/
│  └─ workflows/
│     └─ terraform-plan.yml
├─ .vscode/
│  └─ tasks.json
├─ infra/
│  └─ terraform/
│     ├─ .terraform/
│     │  ├─ providers/
│     │  └─ terraform.tfstate
│     ├─ env/
│     │  └─ dev/
│     │     ├─ backend-values.txt
│     │     └─ terraform.tfvars
│     ├─ modules/
│     ├─ .terraform.lock.hcl
│     ├─ backend.tf
│     ├─ kv-diagnostic-settings.tf
│     ├─ main.tf
│     ├─ network-foundation.tf
│     ├─ outputs.tf
│     ├─ private-dns.tf
│     ├─ providers.tf
│     ├─ tfplan
│     ├─ tfstate-storage-diagnostic-settings.tf
│     ├─ variables.tf
│     └─ versions.tf
├─ .gitignore
├─ DAILY_WORKFLOW.md
├─ PROJECT_CONTEXT.md
├─ PROJECT_PREAMBLE.md
├─ README.md
├─ TECH_SNAPSHOT.md
└─ VSC Default JSON settings.md


- Git ignore (фактический контент)
    Файл: .gitignore
# Terraform
**/.terraform/*
*.tfstate
*.tfstate.*
*.tfplan
infra/terraform/tfplan
crash.log
crash.*.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
.terraformrc
terraform.rc

# Terraform lock file (keep it)
!.terraform.lock.hcl

# Local variables / secrets
*.tfvars
!infra/terraform/env/dev/terraform.tfvars
infra/terraform/env/**/backend-values.txt

# Editor
.vscode/
*.code-workspace

# OS
.DS_Store
Thumbs.db


## 5) Terraform state: что именно появилось в контейнере

В контейнере tfstate появился blob:
- dev/infra.terraform.tfstate

- azurerm_resource_group.core
- azurerm_log_analytics_workspace.law

Источник содержимого: Terraform backend azurerm записывает state в blob при выполнении операций (после init + apply/обновления state). На текущем этапе state содержит минимум для azurerm_resource_group.core и outputs.

## 6) Terraform files (полные тексты)
- 6.1 infra/terraform/backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-genai-dev"
    storage_account_name = "sttfstategenai9307"
    container_name       = "tfstate"
    key                  = "dev/infra.terraform.tfstate"

    use_oidc         = true
    use_azuread_auth = true
  }
}


- 6.2 infra/terraform/providers.tf
provider "azurerm" {
  features {}
}

- 6.3 infra/terraform/versions.tf
terraform {
  required_version = ">= 1.14, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

- 6.4 infra/terraform/variables.tf
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "bu" {
  description = "Business unit (short token, lowercase)"
  type        = string
}

variable "cost_center" {
  description = "Cost center (short token, e.g. cc1234)"
  type        = string
}

- 6.5 infra/terraform/main.tf
locals {
  project  = "azure-genai-secure-landing-zone"
  env      = var.env
  location = var.location

  tags = {
    project    = local.project
    env        = local.env
    owner      = "ig"
    managed_by = "terraform"
  }
}

resource "azurerm_resource_group" "core" {
  name     = "rg-genai-${local.env}"
  location = local.location
  tags     = local.tags
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "kvgenai${local.env}9307"
  location            = local.location
  resource_group_name = azurerm_resource_group.core.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

- 6.6 infra/terraform/outputs.tf
output "env" {
  value = "dev"
}

- 6.7 infra/terraform/env/dev/terraform.tfvars
env      = "dev"
location = "westeurope"

bu          = "itops"
cost_center = "cc0001"

- 6.8 infra/terraform/kv-diagnostic-settings.tf
# Send Key Vault diagnostics to Log Analytics Workspace

data "azurerm_monitor_diagnostic_categories" "kv" {
  resource_id = azurerm_key_vault.kv.id
}

resource "azurerm_monitor_diagnostic_setting" "kv_to_law" {
  name                       = "diag-kv-${local.env}-law"
  target_resource_id         = azurerm_key_vault.kv.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

6.9 infra/terraform/tfstate-storage-diagnostic-settings.tf
# Send tfstate Storage Account diagnostics to Log Analytics Workspace

data "azurerm_storage_account" "tfstate" {
  name                = "sttfstategenai9307"
  resource_group_name = "rg-tfstate-genai-dev"
}

data "azurerm_monitor_diagnostic_categories" "tfstate_sa" {
  resource_id = data.azurerm_storage_account.tfstate.id
}

resource "azurerm_monitor_diagnostic_setting" "tfstate_sa_to_law" {
  name                       = "diag-tfstate-sa-${local.env}-law"
  target_resource_id         = data.azurerm_storage_account.tfstate.id
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

6.10 infra/terraform/network-foundation.tf
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

6.11 infra/terraform/private-dns.tf
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

6.12 .github/workflows/terraform-plan.yml
name: terraform-plan

on:
  pull_request:
    branches: ["main"]
    paths:
      - "infra/terraform/**"
      - ".github/workflows/terraform-plan.yml"
  push:
    branches: ["main"]
    paths:
      - "infra/terraform/**"
      - ".github/workflows/terraform-plan.yml"

permissions:
  id-token: write
  contents: read

jobs:
  plan:
    runs-on: ubuntu-latest

    env:
      ARM_USE_AZUREAD: "true"
      ARM_USE_OIDC: "true"
      ARM_TENANT_ID: ${{ vars.AZURE_TENANT_ID }}
      ARM_CLIENT_ID: ${{ vars.AZURE_CLIENT_ID }}
      ARM_SUBSCRIPTION_ID: ${{ vars.AZURE_SUBSCRIPTION_ID }}

    defaults:
      run:
        working-directory: infra/terraform

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.14.3"

      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}

      - name: Terraform Init
        run: |
          terraform init -reconfigure \
          -backend-config="use_oidc=true" \
          -backend-config="use_azuread_auth=true" \
          -backend-config="tenant_id=${ARM_TENANT_ID}" \
          -backend-config="client_id=${ARM_CLIENT_ID}"

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan (dev)
        run: terraform plan -var-file=env/dev/terraform.tfvars

# trigger run
# trigger 2026-01-13T14:50:01.0846840+01:00


## 7) GitHub Actions OIDC (факты)
- Repo: Yass07/azure-genai-secure-landing-zone
- Workflow: .github/workflows/terraform-plan.yml
- Entra App Registration: gh-oidc-azure-genai-secure-landing-zone
  - CLIENT_ID: e07ab47b-e189-44ac-bca2-e7b27b3f24b1
  - SP_OBJECT_ID: 5cb9647c-0014-4231-887f-a5e1414f0c38
- RBAC на tfstate storage account scope:
  - Reader
  - Storage Blob Data Contributor
- Примечание: backend должен работать без listKeys. Раньше был 403 на listKeys, ушли на Entra ID auth путь.


### 8) Key Vault
- kvgenaidev9307 (rg-genai-dev)

### 9) Monitor diagnostic settings (созданы)
- diag-kv-dev-law (Key Vault -> Log Analytics)
- diag-tfstate-sa-dev-law (tfstate storage account -> Log Analytics, metrics: Transaction, Capacity)

### 10)Network foundation (создано)
- vnet-genai-dev
- snet-workload-dev
- snet-private-endpoints-dev
- nsg-workload-dev + association
- nsg-private-endpoints-dev + association

### 11) Private DNS baseline (создано)
- privatelink.vaultcore.azure.net + vnet link
- privatelink.blob.core.windows.net + vnet link
- privatelink.search.windows.net + vnet link
- privatelink.openai.azure.com + vnet link



