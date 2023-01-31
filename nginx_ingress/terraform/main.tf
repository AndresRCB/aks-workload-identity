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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.8"
    }
  }
}

locals {
  secret_provider_class_name = "azure-csi-prov-ingress"
  ingress_secret_name        = "ingress-tls-csi"
  # secret_name = "randomSecret"
  # secret_value = "AKSWIandKeyVaultIntegrated!"
}

data "azurerm_kubernetes_cluster" "main" {
  name                = var.aks_cluster_name
  resource_group_name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "main" {
  name                = var.ingress_identity_name
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [azurerm_federated_identity_credential.main]
  create_duration = "30s"
}

resource "azurerm_federated_identity_credential" "main" {
  name                = var.federated_identity_credential_name
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = data.azurerm_kubernetes_cluster.main.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.main.id
  subject             = "system:serviceaccount:${var.ingress_namespace}:${var.kubernetes_service_account_name}"

  depends_on = [
    kubernetes_service_account.main
  ]
}

resource "helm_release" "application" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.4.2"
  namespace        = var.ingress_namespace
  create_namespace = false
  verify           = false
  values           = [file("${path.module}/values.yaml")]

  set {
    name = "serviceAccount.create"
    value = "false"
  }

  set {
    name = "serviceAccount.name"
    value = var.kubernetes_service_account_name
  }

  depends_on = [
    time_sleep.wait_30_seconds
  ]
}