output "print_keyvault_secret_command" {
  value = "kubectl exec -it deploy/keyvault-client -n ${kubernetes_namespace.keyvault_client.id} -- cat /mnt/secrets-store/${local.secret_name}"
  description = "Command to print the keyvault secret mounted in the kubernetes client deployment (a test)"
}

output "keyvault_id" {
  value = azurerm_key_vault.main.id
  description = "Resource of the created keyvault"
}