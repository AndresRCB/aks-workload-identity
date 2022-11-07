terraform {
  required_version = "~> 1.2"

  backend "local" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.24"
    }
  }
}

provider "azurerm" {
  features {
    # see https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/features-block
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }

    virtual_machine {
      delete_os_disk_on_deletion     = true
    }
  }
  skip_provider_registration = true
}

resource "azurerm_resource_provider_registration" "container_service" {
  name = "Microsoft.ContainerService"

  feature {
    name       = "EnableWorkloadIdentityPreview"
    registered = true
  }
}
