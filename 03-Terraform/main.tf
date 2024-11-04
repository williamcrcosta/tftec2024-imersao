terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

#provider "azurerm" {
#  features {}
#}


resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location01
}

resource "azurerm_virtual_network" "vnet_hub" {
  name                = "vnet-hub-001"
  address_space       = ["10.10.0.0/16"]
  location            = var.location02
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "sub-srv-001" {
  name                 = "sub-srv-001"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = ["10.10.1.0/24"]
}

/*resource "azurerm_subnet" "sub-srv-001" {
  name                 = "sub-srv-001"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes       = "10.10.1.0/24"
}*/

resource "azurerm_network_security_group" "nsg_hub" {
  name                = "nsg-hub-001"
  location            = var.location02
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-RDP-VM-APPs"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "10.10.1.4"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_hub_association" {
  subnet_id                 = azurerm_subnet.sub-srv-001.id
  network_security_group_id = azurerm_network_security_group.nsg_hub.id
}

resource "azurerm_virtual_network" "vnet_spoke" {
  name                = "vnet-spk-001"
  address_space       = ["10.11.0.0/16"]
  location            = var.location01
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "sub-web-001" {
  name                 = "sub-web-001"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_spoke.name
  address_prefixes     = ["10.11.1.0/24"]
}

resource "azurerm_subnet" "sub-aks-001" {
  name                 = "sub-aks-001"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_spoke.name
  address_prefixes     = ["10.11.2.0/24"]
}

resource "azurerm_subnet" "sub-appgw-001" {
  name                 = "sub-appgw-001"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_spoke.name
  address_prefixes     = ["10.11.3.0/24"]
}

resource "azurerm_subnet" "sub-vint-001" {
  name                 = "sub-vint-001"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_spoke.name
  address_prefixes     = ["10.11.4.0/24"]
}

resource "azurerm_subnet" "sub-db-001" {
  name                 = "sub-db-001"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_spoke.name
  address_prefixes     = ["10.11.5.0/24"]
}

resource "azurerm_network_security_group" "nsg_spoke" {
  name                = "nsg-spk-001"
  location            = var.location01
  resource_group_name = azurerm_resource_group.rg.name
}

/*resource "azurerm_subnet_network_security_group_association" "nsg_spoke_associations" {
  for_each                  = toset([azurerm_subnet.sub-web-001.id, azurerm_subnet.sub-aks-001.id, azurerm_subnet.sub-vint-001.id, azurerm_subnet.sub-db-001.id])
  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.nsg_spoke.id
}*/

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "HubToSpoke"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_hub.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_spoke.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "SpokeToHub"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_spoke.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_hub.id
  allow_forwarded_traffic   = true
}

resource "azurerm_public_ip" "public_ip" {
  name                = "vm-apps-pip"
  location            = var.location02
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic" {
  name                = "vm-apps-nic"
  location            = var.location02
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub-srv-001.id
    private_ip_address_allocation = "Dynamic"
    //public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "vm-apps"
  location            = var.location02
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    name                 = "vm-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
  vm_agent_platform_updates_enabled = true
}

resource "azurerm_storage_account" "storage_prd" {
  name                     = "stotftecsp${random_integer.rand.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location01
  account_tier             = "Standard"
  account_replication_type = "LRS"
  //kind                     = "StorageV2"
  //allow_blob_public_access = true
}

resource "azurerm_storage_container" "container_prd" {
  name                  = "imagens"
  storage_account_name  = azurerm_storage_account.storage_prd.name
  container_access_type = "blob"
}

resource "random_integer" "rand" {
  min = 100000
  max = 999999
}

resource "azurerm_storage_account" "storage_dev" {
  name                     = "stotftecspdev${random_integer.rand.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location01
  account_tier             = "Standard"
  account_replication_type = "LRS"
  //kind                     = "StorageV2"
  //allow_blob_public_access = true
}

resource "azurerm_storage_container" "container_dev" {
  name                  = "imagens"
  storage_account_name  = azurerm_storage_account.storage_dev.name
  container_access_type = "blob"
}


# Bastion Settings Base


resource "azurerm_subnet" "AzureBastionSubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = ["10.10.20.0/26"]
}

resource "azurerm_public_ip" "public_ip-bastion" {
  name                = "bastion-pip"
  location            = var.location02
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "bastion"
  location            = var.location02
  resource_group_name = azurerm_resource_group.rg.name
  scale_units         = 2
  sku = "Developer"
  virtual_network_id = azurerm_virtual_network.vnet_hub.id

/*  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.AzureBastionSubnet.id
    public_ip_address_id = azurerm_public_ip.public_ip-bastion.id
  }*/
}