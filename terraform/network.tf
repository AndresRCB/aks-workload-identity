# Main VNET and subnet
resource "azurerm_virtual_network" "main" {
    name                = var.vnet_name
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    address_space       = [var.vnet_cidr]
}

resource "azurerm_subnet" "main" {
    name                 = var.subnet_name
    resource_group_name  = azurerm_virtual_network.main.resource_group_name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = [var.subnet_cidr]
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

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.bastion_subnet_cidr]
}

resource "azurerm_public_ip" "bastion" {
  name                = var.bastion_public_ip_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
