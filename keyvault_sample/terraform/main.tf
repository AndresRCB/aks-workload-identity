terraform {
  required_version = "~> 1.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.24"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.16"
    }
  }
}

locals {
  secret_provider_class_name = "azure-csi-prov-kv"
  secret_name = "randomSecret"
  secret_value = "AKSWIandKeyVaultIntegrated!"
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_kubernetes_cluster" "main" {
  name                = var.aks_cluster_name
  resource_group_name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "keyvault_client" {
  name                = var.keyvault_identity_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
}

resource "azurerm_federated_identity_credential" "keyvault" {
  name                = var.federated_identity_credential_name
  resource_group_name = data.azurerm_resource_group.main.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = data.azurerm_kubernetes_cluster.main.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.keyvault_client.id
  subject             = "system:serviceaccount:${var.keyvault_client_namespace}:${var.kubernetes_service_account_name}"

  depends_on = [
    kubernetes_service_account.keyvault_client
  ]
}
