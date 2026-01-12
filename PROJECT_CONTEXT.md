# PROJECT_CONTEXT.md — Azure AI Landing Zone (Terraform)

## 1) Цель
Собрать один enterprise-style use case в Azure, который можно показывать на интервью как доказательство практических навыков:
- Azure platform fundamentals (subscriptions, providers, RBAC по мере необходимости)
- Terraform (структура, backend, state, locking, воспроизводимость)
- Security-first подход (диагностика, приватность, минимум публичных экспозиций)
- Связь с Microsoft AI треком (целевая прикладная часть позже: Azure AI / GenAI workload)

---

## 2) Ключевые принципы
- Пошагово, один шаг за раз.
- Фиксируем факты (что реально создано) и решения (что решили и почему).
- Минимум “магии” и предположений.
- Всё важное документируем в двух файлах: TECH_SNAPSHOT.md и PROJECT_CONTEXT.md.

---

## 3) Контекст сертификации AI
Проект задуман как практическая база под AI-направление Microsoft (в т.ч. AZ-AI-102 как целевая сертификация для роли Azure AI Engineer), но реализуется инженерно правильно: сначала foundation (landing zone), затем AI workload слой.

---

## 4) Текущее состояние проекта (факты)
Создано и подтверждено:
- Azure subscription: Azure-genai-demo
- Remote Terraform backend:
  - rg-tfstate-genai-dev
  - sttfstategenai9307
  - container tfstate
  - blob dev/infra.terraform.tfstate
- Terraform:
  - backend azurerm настроен, init выполнен
  - state locking работает
  - создан ресурс azurerm_resource_group.core (в Azure сейчас существует как rg-genai-dev)

---

## 5) Строгий naming (решение)
Принято:
- domain: genai
- bu = itops
- cost_center = cc0001
- region short для westeurope: weu

Важно:
- Для storage accounts применяем укороченный вариант из-за ограничений Azure.
- Текущий bootstrap storage account (sttfstategenai9307) сохраняется как исторический и не переименовывается.

---

## 6) Организация многодневной работы (без потери контекста)
- Каждый день новый чат в ChatGPT Project.
- В начале дня: прикреплены TECH_SNAPSHOT.md и PROJECT_CONTEXT.md и используются как источник правды.
- В конце дня: обновляем оба файла и повторно прикрепляем их в проект.

---

## 7) Roadmap (высокоуровнево)
1) Стабилизировать foundation (landing zone минимум):
   - Log Analytics workspace
   - Diagnostic settings baseline
   - Key Vault (если нужно)
   - VNet/subnets/NSG
   - Private endpoints там, где уместно
2) Определить и реализовать AI workload слой:
   - безопасный доступ (private networking, identities)
   - минимум публичных экспозиций
3) CI/CD:
   - GitHub Actions
   - OIDC вместо секретов (по возможности)
4) Финальная “интервью-упаковка”:
   - архитектурная схема
   - README с шагами воспроизведения
   - демонстрационный сценарий (что показать и как)

## 8) Текущий стек
- Azure
- Terraform
- Azure CLI
- VS Code
- GitHub   

## 9) Архитектурная идея

Проект строится как Azure AI Landing Zone:

- базовый слой (bootstrap)
- security baseline
- networking
- observability
- identity
- AI workload слой
- CI/CD

---

## 10) Что сейчас важно
Это не “поиграться с AI”, а построить архитектуру.
AI — это workload, а не центр вселенной.
Центр — платформа.

---

## 11) Документы системы

Проект всегда опирается на три файла:

1) PROJECT_PREAMBLE.md - зачем мы это делаем
2) PROJECT_CONTEXT.md - что это такое
3) TECH_SNAPSHOT.md - что уже сделано

## 12) Договоренности по стилю

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