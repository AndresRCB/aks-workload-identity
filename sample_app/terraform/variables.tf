variable "resources_subscription_id" {
  type = string
  description = "Subscription ID (i.e., not the full resource ID) of the subscription used by the Cosmos DB account and the AKS cluster"
}

variable "resource_group_name" {
  type = string
  description = "Name of the resource group where the AKS cluster and Cosmos DB account are"
}

variable "aks_cluster_name" {
  type = string
  description = "Name of the AKS cluster where the workload will be deployed"
}

variable "cosmosdb_account_name" {
  type = string
  description = "Name of the Cosmos DB account where this app will create a database"
}

variable "container_image_name" {
  type = string
  description = "Name of the container image to build and use to deploy application to AKS cluster"
}

variable "cosmosdb_identity_name" {
  type = string
  description = "Name to give to the managed identity with Cosmos DB permissions"
}

variable "federated_identity_name" {
  type = string
  description = "Name of the Federated Identity to use from AKS to connect to Cosmos DB."
  default = "aksToCosmosFederatedIdentity"
}


