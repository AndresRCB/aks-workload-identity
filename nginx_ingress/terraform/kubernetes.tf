resource "kubernetes_service_account" "main" {
  metadata {
    name      = var.kubernetes_service_account_name
    namespace = kubernetes_namespace.main.id
    annotations = {
      "azure.workload.identity/client-id" = azurerm_user_assigned_identity.main.client_id
    }
    labels = {
      "azure.workload.identity/use" : "true"
    }
  }
}

resource "kubernetes_namespace" "main" {
  metadata {
    annotations = {
      name = var.ingress_namespace
    }

    name = var.ingress_namespace
  }
}

resource "kubernetes_manifest" "secret_provider_class" {
  depends_on = [
    azurerm_federated_identity_credential.main,
    data.azurerm_kubernetes_cluster.main
  ]

  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      namespace = kubernetes_namespace.main.id
      name = local.secret_provider_class_name
    }

    spec = {
      provider = "azure"
      secretObjects = [
        {
          secretName = local.ingress_secret_name
          type = "kubernetes.io/tls"
          data = [
            {
              objectName = var.ingress_cert_name
              key = "tls.key"
            },
            {
              objectName = var.ingress_cert_name
              key = "tls.crt"
            },
          ]
        },
      ]
      parameters = {
        tenantID = azurerm_user_assigned_identity.main.tenant_id
        clientID = azurerm_user_assigned_identity.main.client_id
        keyvaultName = data.azurerm_key_vault.main.name
        objects = <<EOF
          array:
            - |
              objectName: ${var.ingress_cert_name}
              objectType: secret
        EOF
      }
    }
  }
}
