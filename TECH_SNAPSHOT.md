# TECH_SNAPSHOT.md - Azure AI Landing Zone (Terraform)

## 0) Статус решения
- Remote state: Azure Blob backend работает, locking работает.
- VS Code Tasks: terraform fmt/validate/plan/show/apply используются регулярно.
- GitHub Actions: workflow plan работает через OIDC без секретов.
- Foundation слои применены: observability baseline, network foundation, private DNS baseline.
- AI workload слой: начат и расширен.
  - Azure AI Search: сейчас **выключен** (`enable_search=false`), ресурс Search в Azure отсутствует. При включении создается private Search + PE + diagnostics.
  - Azure OpenAI (private) развернут + diagnostics. Private Endpoints (OpenAI + RAG blob) вынесены под feature-flag `enable_private_endpoints`, сейчас **выключены** (`= false`) для экономии - см. раздел 10.
- Практическая проверка private connectivity (без VM) выполнялась через ACI (временный diagnostic compute):
  - DNS резолв и TCP 443 до Azure AI Search private endpoint **были подтверждены ранее**, когда Search был включен.
  - DNS резолв Azure OpenAI в private IP подтвержден изнутри VNet.
  - TCP 443 до Azure OpenAI private endpoint подтвержден изнутри VNet.
- Диагностический subnet для ACI оставлен как постоянный инструмент для проверок.

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
- Container: tfstate
- Blob key (state): dev/infra.terraform.tfstate
- Diagnostics: metrics-only (Transaction, Capacity). Categories StorageRead/Write/Delete not supported for this account.

### 2.3 Log Analytics Workspace
- Name: log-azure-genai-secure-landing-zone-dev
- RG: rg-genai-dev
- Location: westeurope

### 2.4 Network Foundation
- VNet: vnet-genai-dev (rg-genai-dev, westeurope)
- Subnet: snet-workload-dev
- Subnet: snet-private-endpoints-dev
  - private_endpoint_network_policies = Disabled
- Subnet: snet-aci-test-dev
  - Delegation: Microsoft.ContainerInstance/containerGroups
  - NSG association: nsg-workload-dev
  - Назначение: временный lightweight compute для проверок private DNS/Private IP без постоянной VM
- NSG: nsg-workload-dev (associated to snet-workload-dev)
- NSG: nsg-private-endpoints-dev (associated to snet-private-endpoints-dev)

### 2.5 Private DNS Zones + VNet Links
- privatelink.blob.core.windows.net
  - link: vnetlink-blob-dev
- privatelink.vaultcore.azure.net
  - link: vnetlink-keyvault-dev
- privatelink.openai.azure.com
  - link: vnetlink-openai-dev
- privatelink.search.windows.net
  - link: vnetlink-search-dev

### 2.6 Key Vault
- Name: kvgenaidev9307 (rg-genai-dev)

### 2.7 Azure AI Search

- Статус: **выключен через Terraform feature-flag** (`enable_search = false`), ресурс Search в Azure отсутствует (проверка `az search service show ...` возвращает ResourceNotFound).
- Когда нужен: включаем `enable_search = true` и делаем `plan/apply` (через VS Code Run Tasks). Тогда создается Search service `srchgenaidev9307` (SKU `basic`, `replica_count=1`, `partition_count=1`) с `public_network_access_enabled = false`.
- Причина выключения: это был основной потребитель бюджета на текущем этапе проекта (cost analysis в Portal).
### 2.8 Private Endpoint (Azure AI Search)

- Статус: **выключен вместе с Search**. Private Endpoint `pe-search-dev` в Azure отсутствует (ResourceNotFound).
- Private DNS Zone `privatelink.search.windows.net` и VNet link оставлены в state (их можно держать постоянно, они почти не стоят).
### 2.9 Azure OpenAI (Cognitive Services - kind OpenAI)
- Account: oaigenaidev9307
- Kind: OpenAI
- SKU: S0 (Standard)
- Public network access: Disabled
- Примечание: Доступность kind/SKU проверена в westeurope через Azure CLI.

### 2.10 Private Endpoint (Azure OpenAI)
- Статус: **выключен через feature-flag** (`enable_private_endpoints = false`), pe-openai-dev в Azure отсутствует. Конфигурация ниже создаётся при `enable_private_endpoints = true`.
- Private Endpoint: pe-openai-dev
- Target: oaigenaidev9307
- Subresource: account
- Private DNS zone group: pdzg-openai-dev -> privatelink.openai.azure.com

### 2.11 Observability (Diagnostic settings -> LAW)

- Log Analytics Workspace: `log-azure-genai-secure-landing-zone-dev`.
- Diagnostic Settings включены для:
  - Key Vault (`kvgenaidev9307`)
  - Azure OpenAI (`oaigenaidev9307`)
  - tfstate Storage Account (`sttfstategenai9307`)
  - RAG docs Storage Account (`stgenaidocsdev9307`)
  - Azure AI Search (`srchgenaidev9307`) - **условно**, только когда `enable_search = true` (сейчас Search выключен, поэтому diag тоже отсутствует).
### 2.12 Test VM (attempted) - статус
- VM не создавалась (SKU availability/quota/capacity в westeurope).
- Orphan NIC nic-vm-test-dev был удален terraform apply, так как ресурс отсутствовал в конфигурации (was not in configuration).
- Файл test-vm.tf.disabled остается выключенным.

### 2.13 Network Watcher
- Network Watcher: enabled/present for region westeurope (Azure-managed, typically in NetworkWatcherRG)

## 3) Terraform backend (факты)
- Backend type: azurerm
- Backend scope: subscription (Azure-genai-demo)
- Backend storage (tfstate):
  - resource_group_name: rg-tfstate-genai-dev
  - storage_account_name: sttfstategenai9307
  - container_name: tfstate
  - key: dev/infra.terraform.tfstate
- Auth: Entra ID (use_oidc=true + use_azuread_auth=true)
- State locking: работает (наблюдалось "Acquiring state lock")

## 4) Репозиторий - структура (tree)

Путь репозитория:
- C:\Users\ijask_jid\OneDrive\Desktop\Repos\azure-genai-secure-landing-zone

Структура:
AZURE-GENAI-SECURE-LANDING-ZONE
├─ .github/
│  └─ workflows/
│     └─ terraform-plan.yml
├─ .vscode/
│  └─ tasks.json
├─ infra/
│  └─ terraform/
│     ├─ .terraform/
│     ├─ env/
│     │  └─ dev/
│     │     ├─ backend-values.txt
│     │     └─ terraform.tfvars
│     ├─ modules/
│     ├─ .terraform.lock.hcl
│     ├─ ai-search.tf
│     ├─ ai-search-private-endpoint.tf
│     ├─ azure-openai.tf
│     ├─ azure-openai-private-endpoint.tf
│     ├─ azure-openai-diagnostic-settings.tf
│     ├─ backend.tf
│     ├─ kv-diagnostic-settings.tf
│     ├─ main.tf
│     ├─ network-foundation.tf
│     ├─ outputs.tf
│     ├─ private-dns.tf
│     ├─ providers.tf
│     ├─ test-vm.tf.disabled
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

Git ignore (фактический контент)
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

## 5) Terraform state - что именно появилось в контейнере

Backend container: tfstate
Blob:
- dev/infra.terraform.tfstate

State содержит (актуально после выключения Search `enable_search=false` и Private Endpoints `enable_private_endpoints=false`):
- data.azurerm_client_config.current
- data.azurerm_monitor_diagnostic_categories.kv
- data.azurerm_monitor_diagnostic_categories.openai
- data.azurerm_monitor_diagnostic_categories.tfstate_sa
- data.azurerm_storage_account.tfstate
- azapi_resource.rag_docs_container
- azurerm_cognitive_account.openai
- azurerm_key_vault.kv
- azurerm_log_analytics_workspace.law
- azurerm_monitor_diagnostic_setting.kv_to_law
- azurerm_monitor_diagnostic_setting.openai_to_law
- azurerm_monitor_diagnostic_setting.rag_docs_sa_to_law
- azurerm_monitor_diagnostic_setting.tfstate_sa_to_law
- azurerm_network_security_group.private_endpoints
- azurerm_network_security_group.workload
- azurerm_private_dns_zone.core["blob"]
- azurerm_private_dns_zone.core["keyvault"]
- azurerm_private_dns_zone.core["openai"]
- azurerm_private_dns_zone.core["search"]
- azurerm_private_dns_zone_virtual_network_link.core["blob"]
- azurerm_private_dns_zone_virtual_network_link.core["keyvault"]
- azurerm_private_dns_zone_virtual_network_link.core["openai"]
- azurerm_private_dns_zone_virtual_network_link.core["search"]
- azurerm_resource_group.core
- azurerm_storage_account.rag_docs
- azurerm_subnet.aci_test
- azurerm_subnet.private_endpoints
- azurerm_subnet.workload
- azurerm_subnet_network_security_group_association.aci_test
- azurerm_subnet_network_security_group_association.private_endpoints
- azurerm_subnet_network_security_group_association.workload
- azurerm_virtual_network.core
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

provider "azapi" {}

- 6.3 infra/terraform/versions.tf
terraform {
  required_version = ">= 1.14, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.13"
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
  name                = "log-azure-genai-secure-landing-zone-${local.env}"
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

- 6.9 infra/terraform/tfstate-storage-diagnostic-settings.tf
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

- 6.10 infra/terraform/network-foundation.tf
############################################
# Network foundation (minimal, dev)
# - VNet
# - Subnets: workload + private-endpoints + aci-test
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

variable "subnet_aci_test_prefixes" {
  description = "ACI test subnet prefixes"
  type        = list(string)
  default     = ["10.10.3.0/28"]
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

  private_endpoint_network_policies_enabled = false
}

resource "azurerm_subnet" "aci_test" {
  name                 = "snet-aci-test-${local.env}"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = var.subnet_aci_test_prefixes

  delegation {
    name = "aci-delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
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

resource "azurerm_subnet_network_security_group_association" "aci_test" {
  subnet_id                 = azurerm_subnet.aci_test.id
  network_security_group_id = azurerm_network_security_group.workload.id
}

- 6.11 infra/terraform/private-dns.tf
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

- 6.12 infra/terraform/azure-openai.tf
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

- 6.13 infra/terraform/azure-openai-private-endpoint.tf
############################################
# Azure OpenAI - Private Endpoint
############################################

resource "azurerm_private_endpoint" "openai" {
  name                = "pe-openai-${local.env}"
  resource_group_name = azurerm_resource_group.core.name
  location            = local.location
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-openai-${local.env}"
    private_connection_resource_id = azurerm_cognitive_account.openai.id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }

  private_dns_zone_group {
    name                 = "pdzg-openai-${local.env}"
    private_dns_zone_ids = [azurerm_private_dns_zone.core["openai"].id]
  }
}

- 6.14 infra/terraform/azure-openai-diagnostic-settings.tf
############################################
# Azure OpenAI - Diagnostic settings to LAW
############################################

data "azurerm_monitor_diagnostic_categories" "openai" {
  resource_id = azurerm_cognitive_account.openai.id
}

resource "azurerm_monitor_diagnostic_setting" "openai_to_law" {
  name                       = "diag-openai-${local.env}-law"
  target_resource_id         = azurerm_cognitive_account.openai.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  dynamic "enabled_log" {
    for_each = toset(data.azurerm_monitor_diagnostic_categories.openai.log_category_types)
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = toset(data.azurerm_monitor_diagnostic_categories.openai.metrics)
    content {
      category = metric.value
      enabled  = true
    }
  }
}

- 6.15 .github/workflows/terraform-plan.yml
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

## 8) Day 3 - временные действия и принятая логика (факты)
- Узкое место: нужно было подтвердить private DNS и private connectivity без VM в westeurope.
- Решение: диагностический subnet с delegation под ACI + проверки через az container exec изнутри VNet.
- В ходе диагностики:
  - Были проблемы с PowerShell quoting и передачей сложных команд в --command-line/--exec-command.
  - Рабочий подход: выполнять команды короткими вызовами exec и использовать абсолютные пути внутри контейнера:
    - /sbin/apk
    - /usr/bin/nslookup
    - /usr/bin/nc
- Egress для ACI:
  - NAT Gateway + Public IP применялись временно, затем удалены terraform apply.
  - Если в будущем понадобится подтянуть image или пакеты из интернета, NAT может быть добавлен временно снова.

## 9) Day 4 - Cost control и управление Azure AI Search

- По cost analysis в Azure Portal выявлено, что основной потребитель бюджета на текущем этапе - Azure AI Search.
- Введен feature-flag `enable_search` (в `env/dev/terraform.tfvars`) и применен через Terraform:
  - `enable_search=false` -> Search service, PE и diagnostic setting уничтожены (plan: 3 to destroy).
  - `enable_search=true` -> Search service, PE и diagnostic setting создаются (plan: 3 to add).
- Проверка факта выключения: `terraform state list` не содержит `azurerm_search_service.search` и `azurerm_private_endpoint.search`, при этом Private DNS Zone `core["search"]` и VNet link остаются.
- Отдельно: ACI использовался как временный compute для проверки Private DNS/подключения, после проверки удален.
- Важно по VS Code tasks.json: нельзя терять `options.cwd` (якорь) на `infra/terraform`. Любые правки tasks.json делать минимальным diff и сверять целостность до коммита.

- 6.15 infra/terraform/rag-storage-docs.tf
# RAG documents storage (private-by-default) + Blob Private Endpoint + diagnostics.
# Storage container creation is done via azapi because azurerm_storage_container
# fails under strict network rules (403 AuthorizationFailure) when public access is blocked.

resource "azurerm_storage_account" "rag_docs" {
  name                     = "stgenaidocs${var.env}9307"
  resource_group_name      = azurerm_resource_group.core.name
  location                 = azurerm_resource_group.core.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  # Private-by-default:
  public_network_access_enabled = false

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  tags = local.tags
}

# Blob private endpoint for the Storage Account
resource "azurerm_private_endpoint" "rag_docs_blob" {
  name                = "pe-st-docs-${var.env}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-st-docs-${var.env}"
    private_connection_resource_id = azurerm_storage_account.rag_docs.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-st-docs-${var.env}"
    private_dns_zone_ids = [azurerm_private_dns_zone.core["blob"].id]
  }

  tags = local.tags
}

# Storage diagnostics to LAW
resource "azurerm_monitor_diagnostic_setting" "rag_docs_sa_to_law" {
  name                       = "diag-st-docs-${var.env}-law"
  target_resource_id         = azurerm_storage_account.rag_docs.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "StorageRead"
  }
  enabled_log {
    category = "StorageWrite"
  }
  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
    enabled  = true
  }
}

# Container creation via azapi (see state: azapi_resource.rag_docs_container)
resource "azapi_resource" "rag_docs_container" {
  type      = "Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01"
  name      = "docs"
  parent_id = "${azurerm_storage_account.rag_docs.id}/blobServices/default"

  body = jsonencode({
    properties = {
      publicAccess = "None"
    }
  })
}

- 6.16 infra/terraform/ai-search.tf
# Azure AI Search (main cost driver) - controlled by feature flag enable_search.
resource "azurerm_search_service" "search" {
  count = var.enable_search ? 1 : 0

  name                = "srchgenai${var.env}9307"
  resource_group_name = azurerm_resource_group.core.name
  location            = azurerm_resource_group.core.location

  sku             = "basic"
  replica_count   = 1
  partition_count = 1

  public_network_access_enabled = false
  local_authentication_enabled  = true

  tags = local.tags
}

# Diagnostics to LAW (created only when Search is enabled)
data "azurerm_monitor_diagnostic_categories" "search" {
  count       = var.enable_search ? 1 : 0
  resource_id = azurerm_search_service.search[0].id
}

resource "azurerm_monitor_diagnostic_setting" "search_to_law" {
  count                      = var.enable_search ? 1 : 0
  name                       = "diag-search-${var.env}-law"
  target_resource_id         = azurerm_search_service.search[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "OperationLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

- 6.17 infra/terraform/ai-search-private-endpoint.tf
# Private Endpoint for Azure AI Search - also controlled by enable_search.
resource "azurerm_private_endpoint" "search" {
  count               = var.enable_search ? 1 : 0
  name                = "pe-search-${var.env}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-search-${var.env}"
    private_connection_resource_id = azurerm_search_service.search[0].id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-search-${var.env}"
    private_dns_zone_ids = [azurerm_private_dns_zone.core["search"].id]
  }

  tags = local.tags
}

## 10) Day 5 - Cost control: Private Endpoints (OpenAI + RAG)

- Контекст: инвойс G163831783 (период 01-31.05.2026) показал сетевой расход - Virtual Network Private Link ~CHF 11.75 и Azure DNS Private ~CHF 1.57. Основная статья - всегда-онлайн Private Endpoints.
- Введён feature-flag `enable_private_endpoints` (в `variables.tf`, default `true`; в `env/dev/terraform.tfvars` = `false`). Через `count` гейтит два PE: `azurerm_private_endpoint.openai` (pe-openai-dev) и `azurerm_private_endpoint.rag_docs_blob` (pe-st-docs-dev).
- Применено через VS Code Run Tasks: `plan` = `0 to add, 0 to change, 2 to destroy`, `apply` = `0 added, 0 changed, 2 destroyed`. Оба PE в Azure отсутствуют.
- НЕ трогали: Private DNS зоны и VNet links (остаются, стоят копейки), OpenAI account, RAG storage, KV, сеть, diagnostics.
- Обратно: `enable_private_endpoints = true` + `plan/apply`.
- GitHub: коммит `74a0d9b` ("Budget correction, Disable private endpoints"), terraform-plan run #29 = Success, plan = "No changes" (код и стейт сошлись).
- Изменённые файлы: `variables.tf`, `azure-openai-private-endpoint.tf`, `rag-storage-docs.tf`, `env/dev/terraform.tfvars`.

### 10a) Фиксы VS Code tasks.json (локальный, в .gitignore)
- После миграции ноутбука у тасков терраформа был потерян `options.cwd`, и они выполнялись в корне репо (`init` -> "empty directory", `validate` -> ложный Success на пустом каталоге). Восстановлено: `options.cwd = ${workspaceFolder}/infra/terraform` добавлен на верхнем уровне tasks.json (применяется ко всем таскам).
- Таски `plan` падали в PowerShell с "Too many command line arguments" из-за флагов формы `-var-file=...`/`-out=...`. Переписаны без `=` (`-var-file env/dev/terraform.tfvars -out tfplan`). CI (bash) это не затрагивает.

### 10b) Раздел 6 устарел
- Встроенные тексты TF-файлов в разделе 6 расходятся с реальными (порядок аргументов, шапки-комментарии, `local.env` vs `var.env`, отсутствуют feature-flags). Источник истины - файлы в `infra/terraform`, не раздел 6.
