resource "azurerm_maps_account" "maps" {
  name                = var.maps_account_name
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name

  tags = var.tags
}
