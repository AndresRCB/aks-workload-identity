module "azure_cosmos_db" {
  source              = "Azure/cosmosdb/azurerm"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  cosmos_account_name = var.cosmosdb_account_name
  cosmos_api          = "sql"
  private_endpoint = {
    "pe_endpoint" = {
      enable_private_dns_entry        = true
      dns_zone_group_name             = azurerm_private_dns_zone_virtual_network_link.main.name
      dns_zone_rg_name                = azurerm_private_dns_zone.main.resource_group_name
      is_manual_connection            = false
      name                            = var.pe_name
      private_service_connection_name = var.pe_connection_name
      subnet_name                     = data.azurerm_subnet.main.name
      vnet_name                       = data.azurerm_virtual_network.main.name
      vnet_rg_name                    = data.azurerm_resource_group.main.name
    }
  }
  depends_on = [
    azurerm_resource_group.main,
    azurerm_virtual_network.main,
    azurerm_subnet.main,
    azurerm_private_dns_zone.main,
    azurerm_private_dns_zone_virtual_network_link.main
  ]
}

data "azurerm_cosmosdb_account" "main" {
  resource_group_name = azurerm_resource_group.main.name
  name = var.cosmosdb_account_name

  depends_on = [
    module.azure_cosmos_db
  ]
}

# Private DNS Zone for Cosmos SQL API 
resource "azurerm_private_dns_zone" "main" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  name                  = var.private_dns_vnet_link_name
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
}


