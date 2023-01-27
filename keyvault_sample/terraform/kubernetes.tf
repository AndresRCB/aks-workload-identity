resource "kubernetes_service_account" "keyvault_client" {
  metadata {
    name      = var.kubernetes_service_account_name
    namespace = kubernetes_namespace.keyvault_client.id
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


resource "kubernetes_manifest" "secret_provider_class" {
  depends_on = [
    azurerm_federated_identity_credential.keyvault,
    data.azurerm_kubernetes_cluster.main
  ]

  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      namespace = kubernetes_namespace.keyvault_client.id
      name = local.secret_provider_class_name
    }

    spec = {
      provider = "azure"
      parameters = {
        tenantID = data.azurerm_client_config.current.tenant_id
        clientID = azurerm_user_assigned_identity.keyvault_client.client_id
        keyvaultName = var.keyvault_name
        objects = <<EOF
          array:
            - |
              objectName: randomSecret
              objectType: secret
        EOF
      }
    }
  }
}

resource "kubernetes_deployment" "keyvault_client" {
  depends_on = [
    azurerm_key_vault_secret.main
  ]

  metadata {
    name = "keyvault-client"
    labels = {
      "app" = "nginx"
      "azure.workload.identity/use" = "true"
    }
    namespace = kubernetes_namespace.keyvault_client.id
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.keyvault_client.metadata[0].name
        container {
          name = "main"
          image = "nginx:latest"
          image_pull_policy = "Always"
          volume_mount {
            mount_path = "mnt/secrets-store"
            name = "secrets-mount"
            read_only = true
          }
        }
        volume {
          name = "secrets-mount"
          csi {
            driver = "secrets-store.csi.k8s.io"
            read_only = true
            volume_attributes = {
              secretProviderClass = local.secret_provider_class_name
            }
          }
        }
      }
    }
  }
}
