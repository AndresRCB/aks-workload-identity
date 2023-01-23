# data azurerm_virtual_network main {
#   name = var.virtual_network_name
#   resource_group_name = data.azurerm_resource_group.main.name
# }

# resource "azurerm_subnet" "bastion" {
#   name                 = "AzureBastionSubnet"
#   resource_group_name  = data.azurerm_resource_group.main.name
#   virtual_network_name = data.azurerm_virtual_network.main.name
#   address_prefixes     = [var.bastion_subnet_cidr]
# }

# resource "azurerm_public_ip" "bastion" {
#   name                = var.bastion_public_ip_name
#   location            = data.azurerm_resource_group.main.location
#   resource_group_name = data.azurerm_resource_group.main.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# resource "azurerm_bastion_host" "main" {
#   name                = var.bastion_name
#   location            = data.azurerm_resource_group.main.location
#   resource_group_name = data.azurerm_resource_group.main.name
#   sku                 = "Standard"
#   ip_connect_enabled  = true
#   tunneling_enabled   = true

#   ip_configuration {
#     name                 = "configuration"
#     subnet_id            = azurerm_subnet.bastion.id
#     public_ip_address_id = azurerm_public_ip.bastion.id
#   }
# }

# resource "azurerm_network_interface" "jumpbox" {
#   name                 = "${var.jumpbox_name}-nic"
#   location             = data.azurerm_resource_group.main.location
#   resource_group_name  = data.azurerm_resource_group.main.name
#   enable_ip_forwarding = true

#   ip_configuration {
#     name                          = "${var.jumpbox_name}-configuration"
#     subnet_id                     = azurerm_subnet.main.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# # NOTE: this machine will use default outbound access to reach the internet.
# # If you cannot reach the internet, your network or VMs might have that option disabled.
# resource "azurerm_virtual_machine" "jumpbox" {
#   name                  = var.jumpbox_name
#   location              = azurerm_resource_group.main.location
#   resource_group_name   = azurerm_resource_group.main.name
#   network_interface_ids = [azurerm_network_interface.jumpbox.id]
#   vm_size               = var.jumpbox_size

#   storage_image_reference {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-jammy"
#     sku       = "22_04-lts-gen2"
#     version   = "latest"
#   }

#   storage_os_disk {
#     name              = "${var.jumpbox_name}-disk1"
#     caching           = "ReadWrite"
#     create_option     = "FromImage"
#     managed_disk_type = "Standard_LRS"
#   }

#   os_profile {
#     computer_name  = var.jumpbox_name
#     admin_username = var.jumpbox_admin_name
#   }

#   os_profile_linux_config {
#     disable_password_authentication = true
#     ssh_keys {
#       key_data = file("${var.ssh_key_file}.pub")
#       path     = "/home/${var.jumpbox_admin_name}/.ssh/authorized_keys"
#     }
#   }
# }
