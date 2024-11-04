terraform {
  backend "azurerm" {
    resource_group_name  = "RG-Services"
    storage_account_name = "staremotestate"
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
  }
}

/*provider "azurerm" {
  features {}
}*/
