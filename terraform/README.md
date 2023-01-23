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

```sh
terraform plan
# Check your plan and feel free to use it in the next command (we're just running apply as-is)
terraform apply
```

## Connecting to the control plane (using the cluster)
Our cluster has been created; however, because it's a private cluster, the control plane is only accessible from the IP address of the terraform client who executed this code. We first need to get the k8s cluster credentials, though.

```sh
## Install kubectl
sudo az aks install-cli
# Get cluster credentials for kubectl
$(terraform output -raw cluster_credentials_command)

## Sample output of executed command:
# az aks get-credentials --resource-group rg-private-aks-cli --name aks-private-cluster
```

We're all set now and can use kubectl on our AKS cluster. To test it, run the following command to get the pods on all namespaces:

```sh
kubectl get pods -A
```

### Run command to annotate Kubernetes service account with the client ID of the managed/workload identity
[Details here](https://learn.microsoft.com/en-us/azure/aks/workload-identity-deploy-cluster).
Update the values for serviceAccountName, client-id and serviceAccountNamespace with the Kubernetes service account name and its namespace (here we use testserviceaccountname, 000...000 and default):
```sh
## Sample output to run in your jump box:
cat <<EOF | kubectl apply -f -
               apiVersion: v1
               kind: ServiceAccount
               metadata:
                 annotations:
                   azure.workload.identity/client-id: 00000000-0000-0000-0000-000000000000
                 labels:
                   azure.workload.identity/use: 'true'
               name: testserviceaccountname
               namespace: default
               EOF
```
The following output resembles successful creation of the identity:
```sh
# Serviceaccount/workload-identity-sa created
```

### Command to query OIDC issuer
You need to get your own OIDC issuer URL. Use the command belo for that
```sh
az aks show -n aks-private-cluster -g rg-private-aks-cli --query "oidcIssuerProfile.issuerUrl" -otsv
```

### Run az cli Command to establish federated identity credential
**Note**: terraform is doing this step for you, so only follow the instructions below to set up new identities. In other words, the portion below is for reference! 
You can run the following command with your own values (identity-name, resource-group, issues and service account details)

```sh
## Sample command to run in your jump box:
az identity federated-credential create --name federatedIdentityName --identity-name cosmosdb_identity
               --resource-group rg-private-aks-cli --issuer https://eastus.oic.prod-aks.azure.com/0000000-0000-0000-0000-000000000000/0000000-0000-0000-0000-000000000000/
               --subject system:serviceaccount:serviceAccountNamespace:testserviceaccountname
```

Happy kuberneting!
