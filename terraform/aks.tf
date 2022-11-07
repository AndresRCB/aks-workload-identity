
resource "azurerm_user_assigned_identity" "cluster" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name                = var.cluster_identity
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_virtual_network.main.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.cluster.principal_id
}

resource "azurerm_kubernetes_cluster" "main" {
  name                      = var.cluster_name
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  dns_prefix                = var.cluster_dns_prefix
  private_cluster_enabled   = true
  sku_tier                  = var.cluster_sku_tier
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  

  default_node_pool {
    name                   = "default"
    vm_size                = var.default_node_pool_vm_size
    vnet_subnet_id         = azurerm_subnet.main.id
    node_count             = 1
  }

  identity {
    type = "UserAssigned"
    identity_ids = [ azurerm_user_assigned_identity.cluster.id ]
  }

  network_profile {
    docker_bridge_cidr = var.cluster_docker_bridge_address
    dns_service_ip     = var.cluster_dns_service_ip_address
    network_plugin     = "azure"
    service_cidr       = var.cluster_service_ip_range
  }

  depends_on = [
    azurerm_resource_provider_registration.container_service
  ]
}
