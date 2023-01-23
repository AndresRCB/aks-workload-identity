variable "resource_group_name" {
  type        = string
  description = "name for the resource group"
}

variable "keyvault_name" {
  type = string
  description = "Globally unique name for the Key Vault instance to create"
}

variable "location" {
  type        = string
  description = "location for the resource group"
  default     = "eastus"
}
