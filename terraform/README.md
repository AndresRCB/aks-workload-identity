# Using Terraform for Deployment
This section shows how to deploy and manage a private AKS cluster using your local console (as long as you have access to Azure and admin rights in your device) and [Terraform](https://www.terraform.io/).

## Prerequisites
- Access to Azure (account and network access)
- A console (bash or zsh in this case) where you have admin rights
- An Azure subscription
- [Terraform CLI](https://www.terraform.io/downloads)
- **IMPORTANT** In order to use this with any Azure subscription, you need to enable workload identity preview. Follow the steps [here](https://learn.microsoft.com/en-us/azure/aks/workload-identity-deploy-cluster#register-the-enableworkloadidentitypreview-feature-flag) to do that. The TL;DR is to run the following commands:
```sh
az feature register --namespace "Microsoft.ContainerService" --name "EnableWorkloadIdentityPreview"
# Run the following command until you see that the feature is "Registered" (will take a few minutes)
az feature show --namespace "Microsoft.ContainerService" --name "EnableWorkloadIdentityPreview"
# Once the feature is registered, run this command to refresh the provider registration
az provider register --namespace "Microsoft.ContainerService"
# Check the status of the provider by running this command
az provider show --namespace "Microsoft.ContainerService" --query registrationState
```


## Setting up the environment
Once you have an [Azure account](https://azure.microsoft.com/en-us/free/search/), an Azure subscription, and can sign into the [Azure Portal](https://portal.azure.com/), open a console session.

In order to authenticate to Azure from terraform, you'll need to install the Azure CLI. You can install Azure CLI by running the command below in Linux or MacOS, or you can look for [alternatives here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).
```sh
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

Then, log into your Azure account by running
```sh
az login
```

Once you are in your account, select the subscription with which you want to work.
```sh
## Show available subscriptions
az account show -o table
## Set the subscription you want to use
# az account set -n YOUR_SUBSCRIPTION_NAME
```

Once Azure CLI is authenticated, the Terraform CLI tool will use your azure credentials to manage infrastructure. Now you are ready to start deploying infrastructure with Terraform.

### Executing the terraform scripts
First, clone this repository and go into the `terraform/` folder.

```sh
# First navigate to the location where you want this repo.
# Then, run:
git clone https://github.com/andresrcb/aks-workload-identity.git
cd aks-workload-identity/terraform
```

Now that we can execute the terraform commands needed to bring out the Azure infrastructure, we just need to add the necessary parameters to the code via the command line or with a `.tfvars` file. This repository includes a [sample file](/terraform/terraform.tfvars.sample) that can be copied a starting point.

Remember that the `keyvault_name` value needs to be globally unique (across all of azure), so you need to use a very specific name to your account (a recommendation is to use your username, company name, domain, etc.).

```sh
resource_group_name = "YOURDOMAIN-aks-workload-identity"
keyvault_name = "GLOBALLYUNIQUENAMEHERE"
```

Now you can plan and apply your infrastructure changes by executing `terraform plan` and`terraform apply` commands.

**IMPORTANT**: Due to [limitations on the kuberentes provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/guides/alpha-manifest-migration-guide#mixing-kubernetes_manifest-with-other-kubernetes_-resources), you need to run plan or apply in two separate steps. TL;DR: the cluster must be created before kubernetes resources if the `kubernetes_manifest` resource is used.

```sh
terraform plan -target="module.public_aks_cluster"
# Make sure everthing's good
terraform apply -target="module.public_aks_cluster" -auto-approve
terraform plan
# Again, make sure everthing's good
terraform apply -auto-approve
```

## Connecting to the control plane (using the cluster)
Our cluster has been created and, for security reasons, the control plane is only accessible from the IP address of the terraform client who executed this code. As long as you're using the same client that executed terraform apply, you can now connect to the cluster by following these steps:

```sh
## Install kubectl
sudo az aks install-cli
# Get cluster credentials for kubectl
$(terraform output -raw cluster_credentials_command)

## Sample output of executed command:
# az aks get-credentials --resource-group RESOURCE_GROUP_NAME --name CLUSTER_NAME
```

We're all set now and can use kubectl on our AKS cluster. To test it, run the following command to get the pods on all namespaces:

```sh
kubectl get pods -A
```

### Run command to verify that your kubenetes workload can reach the secret stored in key vault

You just need to execute a `kubectl exec` command that will print the secret value mounted in an nginx pod. There is a terraform `output` to make your life easy if you want to get the command for your setup:
```sh
terraform output print_keyvault_secret_command
```

After running that command, you should see the value of the secret stored in keyvault (by default, it is `AKSWIandKeyVaultIntegrated!`).

Happy kuberneting!
