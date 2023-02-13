variable "resource_group_name" {
  type        = string
  description = "name for the resource group"
}

variable "keyvault_name" {
  type = string
  description = "Globally unique name for the Key Vault instance to create"
}

variable "authorized_ip_cidr_range" {
  type        = string
  description = "CIDR range from which the cluster nodes and control plane will be reachable"
  default     = ""
}

variable "location" {
  type        = string
  description = "location for the resource group"
  default     = "eastus"
}
