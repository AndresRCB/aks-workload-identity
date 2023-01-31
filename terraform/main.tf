data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

module "public_aks_cluster" {
  source = "github.com/AndresRCB/aks-public-cluster"

  resource_group_name = azurerm_resource_group.main.name
  
  depends_on = [
    azurerm_resource_group.main
  ]
}

data "azurerm_kubernetes_cluster" "main" {
  resource_group_name = module.public_aks_cluster.resource_group_name
  name = module.public_aks_cluster.name

  depends_on = [
    module.public_aks_cluster
  ]
}

module "keyvault_setup" {
  source = "../keyvault_sample/terraform"

  resource_group_name = azurerm_resource_group.main.name
  aks_cluster_name = module.public_aks_cluster.name
  keyvault_name = var.keyvault_name
  
  depends_on = [
    module.public_aks_cluster
  ]
}

module "nginx_ingress" {
  source = "../nginx_ingress/terraform"

  resource_group_name = azurerm_resource_group.main.name
  aks_cluster_name = module.public_aks_cluster.name
  keyvault_name = var.keyvault_name
  
  depends_on = [
    module.keyvault_setup
  ]
}
