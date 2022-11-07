data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Managed identity and roles that can be used to access our Cosmos DB account

resource "azurerm_user_assigned_identity" "cosmosdb_client" {
  name                = var.cosmosdb_identity
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}


resource "azurerm_role_assignment" "cosmosdb_contributor" {
  scope                = module.azure_cosmos_db.cosmosdb_id
  role_definition_name = "DocumentDB Account Contributor"
  principal_id         = azurerm_user_assigned_identity.cosmosdb_client.principal_id
  # skip_service_principal_aad_check = true
}

resource "azurerm_cosmosdb_sql_role_assignment" "example" {
  resource_group_name = azurerm_resource_group.main.name
  account_name        = var.cosmosdb_account_name
  role_definition_id  = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.main.name}/providers/Microsoft.DocumentDB/databaseAccounts/${var.cosmosdb_account_name}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azurerm_user_assigned_identity.cosmosdb_client.principal_id
  scope               = module.azure_cosmos_db.cosmosdb_id

  depends_on = [
    module.azure_cosmos_db
  ]
}
