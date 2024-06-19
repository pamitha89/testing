terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.105.0"
      #configuration_aliases = [ azurerm.CoreServices]
    }
  }
}

provider "azurerm" {
  features {}
}  
