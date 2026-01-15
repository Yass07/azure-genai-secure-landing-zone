# PROJECT_CONTEXT.md — Azure AI Landing Zone (Terraform)
# PROJECT_CONTEXT.md - Azure GenAI Secure Landing Zone (Terraform)

## 1) Зачем проект
Собрать один enterprise-style use case в Azure, который можно показывать на интервью как доказательство практических навыков:
- Terraform с remote backend, state, locking, воспроизводимость
- Security-first и private-by-default (минимум публичных экспозиций)
- Networking foundation (VNet, subnets, NSG, Private DNS)
- Observability baseline (Log Analytics + diagnostic settings)
- AI workload слой поверх foundation (Azure AI Search и далее по треку)
- CI/CD через GitHub Actions с OIDC (без секретов)

## 2) Ключевые принципы работы
- Двигаемся микро-шагами, по одному изменению за раз.
- Фиксируем только проверенные факты: что реально создано, что реально работает.
- Никакой "магии": если есть развилка, выбираем самый быстрый и надежный путь.
- Terraform используем там, где это дает пользу для IaC и сертификации. Разовые вещи можно делать через Portal/CLI.
- Без длинных тире.

## 3) Контекст подписки (факты)
- Текущая рабочая подписка: `Azure-genai-demo`
- QuotaId: `PayAsYouGo_2014-09-01`
- SpendingLimit: `Off`
- Попытка найти другую "free trial" подписку через CLI не дала результата. Во втором tenant была ошибка "tenant blocked due to inactivity".

## 4) Текущее состояние проекта (факты)
Создано и подтверждено в Azure (westeurope):
- Remote Terraform backend (tfstate): `rg-tfstate-genai-dev`, storage `sttfstategenai9307`, container `tfstate`, blob `dev/infra.terraform.tfstate`
- Core RG: `rg-genai-dev`
- Log Analytics Workspace: `log-azure-genai-secure-landing-zone-dev`
- Network foundation:
  - VNet `vnet-genai-dev`
  - Subnets `snet-workload-dev`, `snet-private-endpoints-dev`
  - NSG `nsg-workload-dev`, `nsg-private-endpoints-dev` + associations
- Private DNS baseline + VNet links:
  - `privatelink.blob.core.windows.net`
  - `privatelink.vaultcore.azure.net`
  - `privatelink.openai.azure.com`
  - `privatelink.search.windows.net`
- Key Vault: `kvgenaidev9307`
- Azure AI Search:
  - service `srchgenaidev9307` (basic)
  - public network access disabled
  - private endpoint `pe-search-dev` + DNS zone group

Что важно:
- Test VM пытались создать, но в westeurope уперлись в ограничения SKU/capacity/quota. Файл VM переведен в disabled, чтобы не ломать plan/apply.

## 5) Что не тащим в Terraform (решение)
- Бюджет создан через Azure Portal (не через Terraform).
- Цель: минимизировать трение и не усложнять IaC там, где это не дает ценности.

## 6) Структура репозитория и где "истина"
Путь репозитория:
- `C:\Users\ijask_jid\OneDrive\Desktop\Repos\azure-genai-secure-landing-zone`

Главные документы проекта:
- `PROJECT_PREAMBLE.md` - зачем проект и стиль работы
- `PROJECT_CONTEXT.md` - что это такое и как продолжаем
- `TECH_SNAPSHOT.md` - фактическое текущее состояние (ресурсы, артефакты, результаты)

Terraform рабочая папка:
- `infra/terraform`

## 7) Terraform layout: текущая логика
- Пока используем плоскую структуру `.tf` файлов в `infra/terraform` по доменам (network, dns, ai-search, diagnostics).
- Директория `infra/terraform/modules` оставлена под будущие reusable-модули, но сейчас не является обязательной.
- В репозитории есть "disabled" файлы, которые не должны попадать в план:
  - `cost-budget.tf.disabled`
  - `test-vm.tf.disabled`

## 8) CI/CD: GitHub Actions (OIDC)
- Workflow: `.github/workflows/terraform-plan.yml`
- Триггеры: `push`/`pull_request` на `main` с путями `infra/terraform/**`
- Делает: `terraform init`, `terraform validate`, `terraform plan`
- Авторизация: `azure/login@v2` по OIDC, без секретов

## 9) Рабочий дневной цикл (обязательное правило проекта)
- После успешного локального `terraform apply` (через VS Code Tasks):
  - всегда делаем `git commit` + `Sync Changes`
  - затем проверяем, что GitHub Actions workflow (terraform plan) прошел успешно
- Переходим к следующему шагу только после подтверждения, что локальный apply успешен и workflow успешен.

## 10) Известные блокеры и наблюдения (факты)
- Создание VM в `westeurope` неоднократно упиралось в SKU availability / quota семейства. Поэтому VM исключена из Terraform на текущем этапе.
- Для VM был сгенерирован SSH ключ:
  - `~\.ssh\genai_testvm` и `~\.ssh\genai_testvm.pub`

## 11) Roadmap (кратко)
1) Стабилизация foundation (networking, private dns, observability, diagnostics)
2) Расширение AI workload слоя (private endpoints, identity, доступы)
3) Улучшение воспроизводимости (inputs через tfvars, минимизация ручных правок)
4) "Интервью-упаковка": README, архитектурная схема, демонстрационный сценарий


- Язык ответа = язык вопроса.
- Без домыслов.
- Факты проверяются.
- Одна логика.
- Без скачков.
- Без лишних советов.
- Вопросы только при необходимости.
- Ответы не заканчиваются вопросом.
- Без длинных тире.
- Все фиксируется в документах.
---