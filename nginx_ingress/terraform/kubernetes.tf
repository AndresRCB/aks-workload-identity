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
        keyvaultName = var.keyvault_name
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

resource "kubernetes_deployment" "aks_helloworld" {
  depends_on = [
    kubernetes_service_account.main
  ]
  metadata {
    name = "aks-helloworld"
    namespace = var.ingress_namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "aks-helloworld"
      }
    }

    template {
      metadata {
        labels = {
          app = "aks-helloworld"
          "azure.workload.identity/use" = "true"
        }
      }

      spec {
        service_account_name = var.kubernetes_service_account_name
        container {
          name  = "aks-helloworld"
          image = "mcr.microsoft.com/azuredocs/aks-helloworld:v1"
          port {
            container_port = 80
          }
          env {
            name = "TITLE"
            value = "AKS Ingress Demo"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "aks_helloworld" {
  metadata {
    name = "aks-helloworld"
    namespace = var.ingress_namespace
  }
  spec {
    type = "ClusterIP"
    selector = {
      app = "aks-helloworld"
    }
    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_ingress_v1" "aks_helloworld" {
  wait_for_load_balancer = true
  metadata {
    namespace = var.ingress_namespace
    name = "ingress-hello-world"
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"
    }
  }
  spec {
    ingress_class_name = "nginx"
    tls {
      hosts = [
        "demo.arcb.io"
      ]
      secret_name = local.ingress_secret_name
    }
    rule {
      http {
        path {
          path = "/(.*)"
          backend {
            service {
              name = kubernetes_service_v1.aks_helloworld.metadata.0.name
              port {
                number = 80
              }  
            }
          }
        }
      }
    }
  }
}
