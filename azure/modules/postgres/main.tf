resource "azurerm_private_dns_zone" "postgres" {
  name                = "${var.server_name}-zone.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "${var.server_name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.resource_group_name
}

resource "azurerm_postgresql_flexible_server" "postgres" {
  name                          = var.server_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = "16"
  delegated_subnet_id           = var.subnet_id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  administrator_login           = var.admin_username
  administrator_password        = var.admin_password
  storage_mb                    = 32768
  sku_name                      = "GP_Standard_D2ds_v5"
  public_network_access_enabled = false

  lifecycle {
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone
    ]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}
