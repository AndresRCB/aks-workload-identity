# Using Workload Identity From an AKS Deployment to Connect to Cosmos DB

TODO (rough outline below)
- Build container image using Dockerfile and manage_database.py and push it to some registry
- Fill variables using terraform.tfvars (need to create terraform.tfvars.sample for this repo)
- Run terraform from somewhere that can access both the cluster's control plane and the azure subscription
- 