terraform {
  required_version = "1.10.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.16.0"
    }
    external = {
      source = "hashicorp/external"
      version = "2.3.4"
    }
    local = {
      source = "hashicorp/local"
      version = "2.5.2"
    }
    null = {
      source = "hashicorp/null"
      version = "3.2.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscriptionId
  features {}
}