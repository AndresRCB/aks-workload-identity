# Using Workload Identity From an AKS Deployment to Connect to Cosmos DB

## WARNING
This folder is still in development. It was merged to main to avoid losing sample files and client code used in testing. This sample might be deprecated in favor of simpler tests such as printing secrets from Azure Key Vault.

## TODO (rough outline below)
- Build container image using Dockerfile and manage_database.py and push it to some registry
- Fill variables using terraform.tfvars (need to create terraform.tfvars.sample for this repo)
- Run terraform from somewhere that can access both the cluster's control plane and the azure subscription
- 