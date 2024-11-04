terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tftecsp-0001"
    storage_account_name = "tftecsp0001"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
