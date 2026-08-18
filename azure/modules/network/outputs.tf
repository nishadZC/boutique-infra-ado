output "vnet_id" {
  description = "The ID of the Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "The Name of the Virtual Network"
  value       = azurerm_virtual_network.vnet.name
}

output "aks_subnet_id" {
  description = "The ID of the AKS Subnet"
  value       = azurerm_subnet.aks.id
}

output "appgw_subnet_id" {
  description = "The ID of the AppGW Subnet"
  value       = azurerm_subnet.appgw.id
}

output "postgres_subnet_id" {
  description = "The ID of the PostgreSQL Subnet"
  value       = azurerm_subnet.postgres.id
}

output "bastion_host_id" {
  description = "The ID of the Bastion Host"
  value       = azurerm_bastion_host.bastion.id
}
