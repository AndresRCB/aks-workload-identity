provider "azurerm" {
  features {
    # see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/features-block
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }

    virtual_machine {
      delete_os_disk_on_deletion     = true
    }
  }
  skip_provider_registration = true
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.main.kube_config.host
  username               = data.azurerm_kubernetes_cluster.main.kube_config.host.username
  password               = data.azurerm_kubernetes_cluster.main.kube_config.host.password
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.main.kube_config.host.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.main.kube_config.host.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.main.kube_config.host.cluster_ca_certificate)
}

data "azurerm_kubernetes_cluster" "main" {
  name                = var.aks_cluster_name
  resource_group_name = var.resource_group_name
}

data "azurerm_cosmosdb_account" "main" {
  name = var.cosmosdb_account_name
  resource_group_name = var.resource_group_name
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_user_assigned_identity" "cosmosdb_client" {
  name                = var.cosmosdb_identity_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
}

resource "azurerm_role_assignment" "cosmosdb_contributor" {
  scope                = data.azurerm_cosmosdb_account.main.id
  role_definition_name = "DocumentDB Account Contributor"
  principal_id         = azurerm_user_assigned_identity.cosmosdb_client.principal_id
  # skip_service_principal_aad_check = true
}

resource "azurerm_cosmosdb_sql_role_assignment" "example" {
  resource_group_name = data.azurerm_resource_group.main.name
  account_name        = data.azurerm_cosmosdb_account.main.name
  role_definition_id  = "/subscriptions/${var.resources_subscription_id}/resourceGroups/${data.azurerm_resource_group.main.name}/providers/Microsoft.DocumentDB/databaseAccounts/${data.azurerm_cosmosdb_account.main.name}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azurerm_user_assigned_identity.cosmosdb_client.principal_id
  scope               = data.azurerm_cosmosdb_account.main.id
}

## NOTE/TODO: I didn't find the one to replace the CLI command for this.
## NEED TO DIG DEEPER

# resource "azuread_application_federated_identity_credential" "main" {
#   application_object_id = NOPE
# #   audiences             = ["api://AzureADTokenExchange"]
#   issuer                = data.azurerm_kubernetes_cluster.main.oidc_issuer_url
#   # May want to parametrize the values below (including creating a namespace)
#   subject               = "system:serviceaccount:default:serviceaccountname"
# }

# Probably want to change to a kubernetes job which runs once or something
# that takes a request and then runs the cosmos changes. Right now, this will not
# stay running because it's a one-off client.
resource "kubernetes_deployment" "cosmosdb_client" {
  metadata {
    name = "cosmosdb-client"
    labels = {}
    namespace = "default"
  }

  namespace = "default"

  spec {
    replicas = 1

    template {
      metadata {
      }

      spec {
        # TODO: Still need to add service account portions
        container {
          image = var.container_image_name

          name = "main"
          env {
            name  = IDENTITY_CLIENT_ID
            value = azurerm_user_assigned_identity.cosmosdb_client.client_id
          }
          env {
            name  = COSMOSDB_ACCOUNT_ENDPOINT
            value = data.azurerm_cosmosdb_account.main.endpoint
          }

          # MAY NEED MORE ENV VALUES. AVOID ADDING SECRETS THIS WAY

        #   resources {
        #     limits = {
        #       cpu    = "1"
        #       memory = "0.5Gi"
        #     }
        #   }
        }
      }
    }
  }
}
