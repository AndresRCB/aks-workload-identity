terraform {
  required_version = "~> 1.2"

  backend "local" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.24"
    }
  }
}

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

data "azurerm_subscription" "current" {}

resource "azurerm_resource_provider_registration" "example" {
  name = "Microsoft.ContainerService"

  feature {
    name       = "EnableWorkloadIdentityPreview"
    registered = true
  }
}

# INFRASTRUCTURE STARTS HERE

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

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

# Private DNS Zone for SQL API 
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

## CLUSTER RESOURCES

resource "azurerm_user_assigned_identity" "cluster_identity" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name                = var.cluster_identity
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
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
    identity_ids = [ azurerm_user_assigned_identity.cluster_identity.id ]
  }

  network_profile {
    docker_bridge_cidr = var.cluster_docker_bridge_address
    dns_service_ip     = var.cluster_dns_service_ip_address
    network_plugin     = "azure"
    service_cidr       = var.cluster_service_ip_range
  }
}

## BASTION HOST RESOURCES

resource "azurerm_public_ip" "public_ip" {
  name                = var.bastion_public_ip_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.bastion_subnet_cidr]
}

resource "azurerm_bastion_host" "bastion_host" {
  name                = var.bastion_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku = "Standard"
  ip_connect_enabled = true
  tunneling_enabled = true

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

## JUMP BOX INFRA HERE

resource "azurerm_network_interface" "jumpbox_nic" {
    name                 = "${var.jumpbox_name}-nic"
    location             = azurerm_resource_group.main.location
    resource_group_name  = azurerm_resource_group.main.name
    enable_ip_forwarding = true

    ip_configuration {
    name                          = "${var.jumpbox_name}-configuration"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    }
}

# NOTE: this machine will use default outbound access to reach the internet.
# If you cannot reach the internet, your network or VMs might have that option disabled.
resource "azurerm_virtual_machine" "jumpbox_vm" {
    name                  = var.jumpbox_name
    location              = azurerm_resource_group.main.location
    resource_group_name   = azurerm_resource_group.main.name
    network_interface_ids = [azurerm_network_interface.jumpbox_nic.id]
    vm_size               = var.jumpbox_size

    storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
    }

    storage_os_disk {
    name              = "${var.jumpbox_name}-disk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    }

    os_profile {
    computer_name  = var.jumpbox_name
    admin_username = var.jumpbox_admin_name
    }

    os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = file("${var.ssh_key_file}.pub")
      path = "/home/${var.jumpbox_admin_name}/.ssh/authorized_keys"
    }
    }
}

## COSMOS

module "azure_cosmos_db" {
  source              = "Azure/cosmosdb/azurerm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
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
      subnet_name                     = azurerm_subnet.main.name
      vnet_name                       = azurerm_virtual_network.main.name
      vnet_rg_name                    = azurerm_resource_group.main.name
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

##Cosmos DB Identity 
resource "azurerm_user_assigned_identity" "cosmosdb_identity" {
  name                = var.cosmosdb_identity
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}


resource "azurerm_role_assignment" "cosmosdb_contributor" {
  scope                = module.azure_cosmos_db.cosmosdb_id
  role_definition_name = "DocumentDB Account Contributor"
  principal_id         = azurerm_user_assigned_identity.cosmosdb_identity.principal_id
  # skip_service_principal_aad_check = true
}

resource "azurerm_cosmosdb_sql_role_assignment" "example" {
  resource_group_name = azurerm_resource_group.main.name
  account_name        = var.cosmosdb_account_name
  role_definition_id  = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.main.name}/providers/Microsoft.DocumentDB/databaseAccounts/${var.cosmosdb_account_name}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azurerm_user_assigned_identity.cosmosdb_identity.principal_id
  scope               = module.azure_cosmos_db.cosmosdb_id

  depends_on = [
    module.azure_cosmos_db
  ]
}
