# Terraform Block
terraform {
  required_version = ">=1.2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0"
    }
  }
  # Backend Block
  backend "azurerm" {
    resource_group_name  = "RG-TF-STATE"
    storage_account_name = "tfstate4azuresa"
    container_name       = "tfstate"
    key                  = "azuresa-tfstate"
  }
}

# Provider Block
provider "azurerm" {
  # Configuration options
  features {}
}