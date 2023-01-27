output "subscription_id" {
  value = data.azurerm_subscription.current.subscription_id
  description = "Subscription ID (i.e., not the full resource ID) of the subscription used by the AKS cluster and other resources"
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
  description = "Name of the resource group where the AKS cluster and other resources are"
}

output "aks_cluster_name" {
  value = module.public_aks_cluster.name
  description = "Name of the AKS cluster created for this example"
}

output "cluster_invoke_command" {
  value = module.public_aks_cluster.invoke_command
  description = "Sample command to execute k8s commands on the cluster using az cli"
}

output "cluster_credentials_command" {
  value = module.public_aks_cluster.credentials_command
  description = "Command to get the cluster's credentials with az cli"
}

output "cluster_oidc_issuer_url" {
  value = module.public_aks_cluster.oidc_issuer_url
  description = "URL of the OIDC issuer in the cluster (used for workload identity)"
}

output "print_keyvault_secret_command" {
  value = module.keyvault_setup.print_keyvault_secret_command
  description = "Command to print the keyvault secret mounted in the kubernetes client deployment (a test)"
}
