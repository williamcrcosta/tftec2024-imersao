# Resource Group
variable "resource_group_name" {
  default = "rg-tftecsp-0001"
}

# Regions
variable "location01" {
  #  default = "uksouth" # Original
  #  default = "eastus2"
  default = "West US"
}

variable "location02" {
  #  default = "brazilsouth"
  #  default = "centralus"
  default = "North Europe"
}

# Credentials
variable "admin_username" {
  default = "admin.tftec"
}

variable "admin_password" {
  default = "Partiunuvem@2024"
}

variable "tags" {
  default = {
    Environment = "Labs"
    Evento        = "Imersão TFTEC 2024"
  }
}