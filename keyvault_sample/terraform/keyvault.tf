resource "azurerm_key_vault" "main" {
  name                = var.keyvault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"
  tags = {}
}

resource "azurerm_key_vault_access_policy" "creator" {
  key_vault_id = azurerm_key_vault.main.id
  object_id = data.azurerm_client_config.current.object_id
  tenant_id = data.azurerm_client_config.current.tenant_id

  certificate_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Purge",
    "Recover",
    "Restore"
  ]

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Purge"
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge"
  ]
}

resource "azurerm_key_vault_access_policy" "keyvault_client" {
  key_vault_id = azurerm_key_vault.main.id
  object_id = azurerm_user_assigned_identity.keyvault_client.principal_id
  tenant_id = azurerm_user_assigned_identity.keyvault_client.tenant_id
  
  certificate_permissions = [
    "Get",
  ]

  key_permissions = [
    "Get",
  ]

  secret_permissions = [
    "Get"
  ]
}

resource "azurerm_key_vault_secret" "main" {
  name         = local.secret_name
  value        = local.secret_value
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_key_vault_access_policy.creator
  ]
}