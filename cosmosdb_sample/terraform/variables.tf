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
  default = "cosmosdb-client"
}

variable "kubernetes_service_account_name" {
  type = string
  description = "Name to give to the kubernetes service account to map to a user managed identity"
  default = "cosmosdbclient"
}

variable "federated_identity_credential_name" {
  type = string
  description = "Name of the Federated Identity Credential to use from AKS to connect to Cosmos DB"
  default = "aksToCosmosdbFederatedIdentity"
}

variable "cosmosdb_client_namespace" {
  type = string
  description = "Kubernetes namespace to create and use for the cosmosdb client workload and service account"
  default = "cosmosdb-client"
}

variable "dns_zone_group_name" {
  type        = string
  description = "Zone Group Name for PE"
  default     = "pe_zone_group"
}

variable "pe_name" {
  type        = string
  description = "Private Endpoint Name"
  default     = "cosmosdb_pe"
}

variable "pe_connection_name" {
  type        = string
  description = "Private Endpoint Connection Name"
  default     = "pe_connection"
}

variable "throughput" {
  type        = number
  description = "Cosmos DB database throughput"
  default     = 400
  validation {
    condition     = var.throughput >= 400 && var.throughput <= 1000000
    error_message = "Cosmos db manual throughput should be equal to or greater than 400 and less than or equal to 1000000."
  }
  validation {
    condition     = var.throughput % 100 == 0
    error_message = "Cosmos db throughput should be in increments of 100."
  }
}

# variable "jumpbox_name" {
#   type        = string
#   description = "Name of the jump box VM for"
#   default     = "vm-jumpbox"
# }

# variable "jumpbox_admin_name" {
#   type        = string
#   description = "Name of the admin username in the jump box"
#   default     = "azureuser"
# }

# variable "jumpbox_size" {
#   type        = string
#   description = "Size of the jump box VM"
#   default     = "Standard_D2s_v3"
# }

# variable "bastion_public_ip_name" {
#   type        = string
#   description = "Name of the public IP address for Azure Bastion"
#   default     = "bastion-ip-aks"
# }

# variable "bastion_subnet_cidr" {
#   type        = string
#   description = "CIDR range for the cluster subnet"
#   default     = "172.16.255.0/24"
# }

# variable "bastion_name" {
#   type        = string
#   description = "Name of the Azure Bastion that connects to the cluster's VNET"
#   default     = "bastion-private-aks"
# }
