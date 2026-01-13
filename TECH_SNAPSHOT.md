# TECH_SNAPSHOT.md — Azure AI Landing Zone (Terraform)

## 0) Статус решения
- Remote state настроен и работает (Azure Blob).
- Terraform init/plan/apply выполнялись.
- Реальные ресурсы в Azure зафиксированы ниже.


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

### 2.4 tfstate blob
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
├── .gitignore
├── README.md
└── infra
    └── terraform
        ├── .terraform.lock.hcl
        ├── backend.tf
        ├── main.tf
        ├── outputs.tf
        ├── providers.tf
        ├── variables.tf
        ├── versions.tf
        ├── .terraform/
        │   ├── terraform.tfstate
        │   └── providers/...
        ├── env
        │   └── dev
        │       ├── backend-values.txt
        │       └── terraform.tfvars
        └── modules
- .terraform/ (локальная папка Terraform, должна быть игнорирована в git)

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
# Intentionally empty for now.
# Resources will be added step-by-step after:
# - backend strategy is decided
# - auth method is decided (OIDC vs SPN vs interactive)
# - naming convention is agreed

- 6.6 infra/terraform/outputs.tf
output "env" {
  value = "dev"
}

- 6.7 infra/terraform/env/dev/terraform.tfvars
env      = "dev"
location = "westeurope"

bu          = "itops"
cost_center = "cc0001"

