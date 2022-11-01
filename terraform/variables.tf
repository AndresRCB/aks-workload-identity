variable "resource_group_name" {
  type        = string
  description = "name for the resource group"
}

variable "ssh_key_file" {
  type        = string
  description = "Location of the private SSH key in the local file system"
}

variable "location" {
  type        = string
  description = "location for the resource group"
  default     = "eastus"
}

variable "vnet_name" {
  type        = string
  description = "Name of the virtual network where all resources will be"
  default     = "vnet-private-aks"
}

variable "vnet_cidr" {
  type        = string
  description = "CIDR range for the virtual network"
  default     = "172.16.0.0/16"
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet where all resources will be"
  default     = "subnet-private-aks"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR range for the cluster subnet"
  default     = "172.16.0.0/20"
}

variable "cluster_name" {
  type        = string
  description = "Name for the private AKS cluster"
  default     = "aks-private-cluster"
}

variable "cluster_dns_prefix" {
  type        = string
  description = "DNS prefix for AKS cluster"
  default     = "aksprivatecluster"
}

variable "cluster_sku_tier" {
  type        = string
  description = "SKU tier selection between Free and Paid"
  default     = "Free"
}

variable "cluster_identity" {
  type        = string
  description = "Name of the MSI (Managed Service Identity) for the AKS cluster"
  default     = "identity-private-aks-cluster"
}

variable "cluster_docker_bridge_address" {
  type        = string
  description = "CIDR range for the docker bridge in the cluster"
  default     = "172.17.0.1/16"
}

variable "cluster_dns_service_ip_address" {
  type        = string
  description = "IP address for the cluster's DNS service"
  default     = "172.16.16.254"
}

variable "cluster_service_ip_range" {
  type        = string
  description = "CIDR range for the cluster's kube-system services"
  default     = "172.16.16.0/24"
}

variable "default_node_pool_vm_size" {
  type        = string
  description = "Size of nodes in the k8s cluster's default node pool"
  default     = "Standard_D2s_v3"
}

variable "jumpbox_name" {
  type        = string
  description = "Name of the jump box VM for"
  default     = "vm-jumpbox"
}

variable "jumpbox_admin_name" {
  type        = string
  description = "Name of the admin username in the jump box"
  default     = "azureuser"
}

variable "jumpbox_size" {
  type        = string
  description = "Size of the jump box VM"
  default     = "Standard_D2s_v3"
}

variable "bastion_public_ip_name" {
  type        = string
  description = "Name of the public IP address for Azure Bastion"
  default     = "bastion-ip-aks"
}

variable "bastion_subnet_cidr" {
  type        = string
  description = "CIDR range for the cluster subnet"
  default     = "172.16.255.0/24"
}

variable "bastion_name" {
  type        = string
  description = "Name of the Azure Bastion that connects to the cluster's VNET"
  default     = "bastion-private-aks"
}
