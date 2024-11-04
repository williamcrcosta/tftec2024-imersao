output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "vnet_hub_id" {
  value = azurerm_virtual_network.vnet_hub.id
}

output "vnet_spoke_id" {
  value = azurerm_virtual_network.vnet_spoke.id
}

output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
}