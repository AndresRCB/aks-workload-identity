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
}

resource "azurerm_resource_provider_registration" "example" {
  name = "Microsoft.ContainerService"

  feature {
    name       = "EnableWorkloadIdentityPreview"
    registered = true
  }
}

# INFRASTRUCTURE STARTS HERE

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
    name                = var.vnet_name
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    address_space       = [var.vnet_cidr]
}

resource "azurerm_subnet" "subnet" {
    name                 = var.subnet_name
    resource_group_name  = azurerm_virtual_network.vnet.resource_group_name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = [var.subnet_cidr]
}

## CLUSTER RESOURCES

resource "azurerm_user_assigned_identity" "aks_identity" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = var.cluster_identity
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                      = var.cluster_name
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  dns_prefix                = var.cluster_dns_prefix
  private_cluster_enabled   = true
  sku_tier                  = var.cluster_sku_tier
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  

  default_node_pool {
    name                   = "default"
    vm_size                = var.default_node_pool_vm_size
    vnet_subnet_id         = azurerm_subnet.subnet.id
    node_count             = 1
  }

  identity {
    type = "UserAssigned"
    identity_ids = [ azurerm_user_assigned_identity.aks_identity.id ]
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
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.bastion_subnet_cidr]
}

resource "azurerm_bastion_host" "bastion_host" {
  name                = var.bastion_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
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
    location             = azurerm_resource_group.rg.location
    resource_group_name  = azurerm_resource_group.rg.name
    enable_ip_forwarding = true

    ip_configuration {
    name                          = "${var.jumpbox_name}-configuration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    }
}

# NOTE: this machine will use default outbound access to reach the internet.
# If you cannot reach the internet, your network or VMs might have that option disabled.
resource "azurerm_virtual_machine" "jumpbox_vm" {
    name                  = var.jumpbox_name
    location              = azurerm_resource_group.rg.location
    resource_group_name   = azurerm_resource_group.rg.name
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
