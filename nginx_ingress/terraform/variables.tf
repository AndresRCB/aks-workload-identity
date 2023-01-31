variable "aks_cluster_name" {
  type = string
  description = "Name of the AKS cluster where resources will be deployed"
}

variable "resource_group_name" {
  type = string
  description = "Name of the resource group where the AKS cluster and Azure Key Vault are"
}

variable "location" {
  type = string
  description = "Azure region for all resources"
}

variable "keyvault_name" {
  type = string
  description = "Globally unique name to give to the Key Vault instance"
}

variable "ingress_cert_name" {
  type = string
  description = "Name of the ingress TLS certificate in Key Vault"
  default = "ingress-nginx"
}

variable "ingress_cert_cn" {
  type = string
  description = "Common Name (CN) of the ingress TLS certificate"
  default = "testdomain.com"
}

variable "ingress_identity_name" {
  type = string
  description = "Name to give to the managed identity with Key Vault permissions"
  default = "ingress-nginx"
}

variable "kubernetes_service_account_name" {
  type = string
  description = "Name to give to the kubernetes service account to map to a user managed identity"
  default = "ingressnginx"
}

variable "federated_identity_credential_name" {
  type = string
  description = "Name of the Federated Identity Credential to use from AKS to connect to Azure Key Vault."
  default = "ingressToKeyvaultFederatedIdentity"
}

variable "ingress_namespace" {
  type = string
  description = "Kubernetes namespace to create for ingress-nginx resources"
  default = "ingress-nginx"
}
