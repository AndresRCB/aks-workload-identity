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

resource "kubernetes_service_account" "keyvault_client" {
  metadata {
    name      = var.kubernetes_service_account_name
    namespace = var.keyvault_client_namespace
    annotations = {
      "azure.workload.identity/client-id" = azurerm_user_assigned_identity.keyvault_client.client_id
    }
    labels = {
      "azure.workload.identity/use" : "true"
    }
  }
}

resource "kubernetes_namespace" "keyvault_client" {
  metadata {
    annotations = {
      name = var.keyvault_client_namespace
    }

    name = var.keyvault_client_namespace
  }
}

# resource "kubernetes_deployment" "keyvault_client" {
#   metadata {
#     name = "keyvault-client"
#     labels = {}
#     namespace = var.keyvault_client_namespace
#   }

#   namespace = var.keyvault_client_namespace

#   spec {
#     replicas = 1

#     template {
#       metadata {
#       }

#       spec {
#         # TODO: Still need to add service account portions
#         container {
#           image = var.container_image_name

#           name = "main"

#           # MAY NEED MORE ENV VALUES. AVOID ADDING SECRETS THIS WAY

#         #   resources {
#         #     limits = {
#         #       cpu    = "1"
#         #       memory = "0.5Gi"
#         #     }
#         #   }
#         }
#       }
#     }
#   }
# }
