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
# Feature flag: allow turning Azure AI Search on/off to control cost
variable "enable_search" {
  type        = bool
  description = "Feature flag: enable or disable Azure AI Search and its dependent resources (PE, diagnostics)."
  default     = true
}
