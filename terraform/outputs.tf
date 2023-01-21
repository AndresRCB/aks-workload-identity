output "subscription_id" {
  value = data.azurerm_subscription.current.subscription_id
  description = "Subscription ID (i.e., not the full resource ID) of the subscription used by the Cosmos DB account and the AKS cluster"
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
  description = "Name of the resource group where the AKS cluster and Cosmos DB account are"
}

output "cosmosdb_account_name" {
  value = data.azurerm_cosmosdb_account.main.name
  description = "Name of the Cosmos DB account created for this example"
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
  description = "Name of the AKS cluster created for this example"
}

output "cluster_invoke_command" {
  value = "az aks command invoke --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name} --command \"kubectl get pods -n kube-system\""
  description = "Sample command to execute k8s commands on the cluster using az cli"
}

output "jumpbox_login_command" {
  value = "az network bastion ssh --name ${azurerm_bastion_host.main.name} --resource-group ${azurerm_resource_group.main.name} --target-resource-id ${azurerm_virtual_machine.jumpbox.id} --auth-type ssh-key --username ${var.jumpbox_admin_name} --ssh-key ${var.ssh_key_file}"
  description = "Command to connect to the jumpbox VM"
}

output "cluster_credentials_command" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
  description = "Command to get the cluster's credentials with az cli"
}

output "managed_identity_federated_credential" {
  value = <<-COMMAND
        ### Bash Command to annotate Kubernetes service account with the client ID of the managed/workload identity###
                cat <<EOF | kubectl apply -f -
                apiVersion: v1
                kind: ServiceAccount
                metadata:
                  annotations:
                    azure.workload.identity/client-id: ${azurerm_user_assigned_identity.cosmosdb_client.client_id}
                  labels:
                    azure.workload.identity/use: 'true'
                name: testserviceaccountname
                namespace: default
                EOF
        ### az cli Command to establish federated identity credential ###
                az identity federated-credential create --name federatedIdentityName --identity-name ${azurerm_user_assigned_identity.cosmosdb_client.name}
                --resource-group ${azurerm_resource_group.main.name} --issuer ${azurerm_kubernetes_cluster.main.oidc_issuer_url} 
                --subject system:serviceaccount:serviceAccountNamespace:testserviceaccountname
         COMMAND
  description = "Command to annotate Kubernetes service account with the client ID of the managed/workload identity "
}
