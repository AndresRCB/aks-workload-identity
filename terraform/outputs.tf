output "cluster-invoke-command" {
  value = "az aks command invoke --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.aks_cluster.name} --command \"kubectl get pods -n kube-system\""
  description = "Sample command to execute k8s commands on the cluster using az cli"
}

output "jumpbox-login-command" {
  value = "az network bastion ssh --name ${azurerm_bastion_host.bastion_host.name} --resource-group ${azurerm_resource_group.main.name} --target-resource-id ${azurerm_virtual_machine.jumpbox_vm.id} --auth-type ssh-key --username ${var.jumpbox_admin_name} --ssh-key ${var.ssh_key_file}"
  description = "Command to connect to the jumpbox VM"
}

output "cluster-credentials-command" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.aks_cluster.name}"
  description = "Command to get the cluster's credentials with az cli"
}

output "managed-identity-client-id" {
  value = join(" ", ["cat <<EOF | kubectl apply -f -",
                      "apiVersion: v1",
                      "kind: ServiceAccount",
                      "metadata:",
                      "annotations:",
                      "azure.workload.identity/client-id: ${azurerm_user_assigned_identity.main.id}",
                      "labels:",
                      "azure.workload.identity/use: 'true'",
                      "name: testserviceaccountname",
                      "namespace: default",
                      "EOF"
          ]) 
  description = "Bash Command to annotate Kubernetes service account with the client ID of the managed/workload identity "
}

output "federated-credential" {
  value = <<EOT
      az identity federated-credential create --name federatedIdentityName --identity-name ${azurerm_user_assigned_identity.main.name}"
      --resource-group ${azurerm_resource_group.main.name} --issuer ${azurerm_kubernetes_cluster.aks_cluster.oidc_issuer_url} 
      --subject system:serviceaccount:serviceAccountNamespace:testserviceaccountname
  EOT
  description = "Command to establish federated identity credential with az cli"
}
##az identity federated-credential create --name federatedIdentityName --identity-name userAssignedIdentityName --resource-group resourceGroupName --issuer ${AKS_OIDC_ISSUER} --subject system:serviceaccount:serviceAccountNamespace:serviceAccountName
