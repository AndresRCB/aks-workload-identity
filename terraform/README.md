# Using Terraform for Deployment
This section shows how to deploy and manage a private AKS cluster using your local console (as long as you have access to Azure and admin rights in your device) and [Terraform](https://www.terraform.io/).

## Prerequisites
- Access to Azure (account and network access)
- A console (bash or zsh in this case) where you have admin rights
- An Azure subscription
- [Terraform CLI](https://www.terraform.io/downloads)

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

## Creating the Infrastruture
In this section, we will create an SSH key and instruct terraform to create our infrastructure.

### Creating an SSH key
First, we need to create an SSH key to access the Linux jump box VM that Terraform will create for us. While we will add instructions on how to create said key (for MacOS and Linux), you can use an existing SSH key if you prefer (keeing in mind that Azure only supports RSA SSH2 key signatures of at least 2048 bits in length).

Run the following command in your console (replace the email address with your own).
```sh
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

We can leave the default values that `ssh-keygen` prompts (key location and no passphrase); however, we need to keep the key location at hand (`~/.ssh/id_rsa` by default) because we will need it as an input in our terraform commands/script.

### Executing the terraform scripts
First, clone this repository and go into the `terraform/` folder.

```sh
# First navigate to the location where you want this repo.
# Then, run:
git clone https://github.com/andresrcb/aks-private-cluster.git
cd aks-private-cluster/terraform
```

Now that we can execute the terraform commands needed to bring out the Azure infrastructure, we just need to add the necessary parameters to the code via the command line or with a `.tfvars` file. This repository includes a [sample file](/terraform/terraform.tfvars.sample) that can be copied a starting point.

Assuming that our SSH key is at `~/.ssh/id_rsa`, we can create a `terraform.tfvars` file to avoid having to pass them in the CLI, setting them as environment variables or being prompted by them when running terraform plan/apply (to override other values, check out the sample file).

```sh
resource_group_name = "private-aks-rg"
ssh_key_file = "~/.ssh/id_rsa"
```

Now you can plan and apply your infrastructure changes by executing `terraform plan` and`terraform apply` commands.

```sh
terraform plan
# Check your plan and feel free to use it in the next command (we're just running apply as-is)
terraform apply
```

## Connecting to the control plane (using the cluster)
Our cluster has been created; however, because it's a private cluster, the control plane is not accessible through the internet (i.e., our admin device). This is by design and desirable for security, so we'll have to access it indirectly through Azure-provided tooling.

I recommend two options to connect to the cluster:
1. Azure CLI and `command invoke` ([details here](https://docs.microsoft.com/en-us/azure/aks/command-invoke))
2. Using a jump box and [Azure Bastion](https://docs.microsoft.com/en-us/azure/bastion/bastion-overview).

### Azure AKS command invoke
We can run `kubectl` commands in a private AKS cluster by using [command invoke](https://docs.microsoft.com/en-us/azure/aks/command-invoke). We will need to pass inputs such as file names in both the `kubectl` command and in the az wrapper command, but it makes things simple when we only need to take a quick action in the cluster. Here's an example:
```sh
# Get the proper command with infra parameters using terraform output
terraform output -raw cluster-invoke-command

# Basic command example
az aks command invoke \
                --resource-group $RESOURCE_GROUP \
                --name $CLUSTER_NAME \
                --command "kubectl get pods -n kube-system"

# Example with input file
az aks command invoke \
                --resource-group $RESOURCE_GROUP \
                --name $CLUSTER_NAME \
                --command "kubectl apply -f deployment.yaml -n default" \
                --file deployment.yaml
```

### Connecting using a jump box and Azure Bastion
An Azure Bastion and a Jumpbox are part of the terraform files in this section. The SSH key generated at the beginning of this guide was used for the jump box VM, so the command below should establish a connection to the jump box VM.

```sh
# az network bastion ssh \
#                 --name $BASTION_HOST_NAME \
#                 --resource-group $RESOURCE_GROUP \
#                 --target-resource-id $JUMPBOX_ID \
#                 --auth-type ssh-key \
#                 --username $JUMPBOX_ADMIN_NAME \
#                 --ssh-key ~/.ssh/id_rsa 
# To get the command, use terraform output:
$(terraform output -raw jumpbox-login-command)
```

At this point, we have logged into our jump box via SSH and can execute commands. This machine will not have Azure CLI or kubectl installed, so we need to set it up. We just need to run the following commands in the VM **in order** (follow instructions as needed):

```sh
## Install azure cli
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
## log into Azure
az login
## Install kubectl
sudo az aks install-cli
```

Finally, we need to get the k8s cluster credentials. Because our environment was set up locally, we need to run the following command in our local machine first and then copy that command for use in the VM session (this is in order to replace the environment variables into the command).

```sh
# Get cluster credentials for kubectl
terraform output -raw cluster-credentials-command

## Sample output to run in your jump box:
# az aks get-credentials --resource-group rg-private-aks-cli --name aks-private-cluster
```

We're all set now and can use kubectl on our private AKS cluster. To test it, run the following command to get your cluster's kube-system pods:
```sh
kubectl get pods -n kube-system
```

Happy kuberneting!