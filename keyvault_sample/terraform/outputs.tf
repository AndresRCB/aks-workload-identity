output "keyvault_managed_identity_federated_credential" {
  value = <<-COMMAND
        ### Bash Command to annotate Kubernetes service account with the client ID of the managed/workload identity###
                cat <<EOF | kubectl apply -f -
                apiVersion: v1
                kind: ServiceAccount
                metadata:
                  annotations:
                    azure.workload.identity/client-id: ${azurerm_user_assigned_identity.keyvault_client.client_id}
                  labels:
                    azure.workload.identity/use: 'true'
                name: testserviceaccountname
                namespace: default
                EOF
        ### az cli Command to establish federated identity credential ###
                az identity federated-credential create --name federatedIdentityName --identity-name ${azurerm_user_assigned_identity.keyvault_client.name}
                --resource-group ${data.azurerm_resource_group.main.name} --issuer ${data.azurerm_kubernetes_cluster.main.oidc_issuer_url} 
                --subject system:serviceaccount:serviceAccountNamespace:testserviceaccountname
         COMMAND
  description = "Command to annotate Kubernetes service account with the client ID of the managed/workload identity "
}
