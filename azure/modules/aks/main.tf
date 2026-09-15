resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  sku_tier            = "Free"
  default_node_pool {
    name                = "default"
    enable_auto_scaling = false
    node_count          = 2
    vm_size             = "Standard_DC2ds_v3"
    vnet_subnet_id      = var.subnet_id
  }

  linux_profile {
    admin_username = "azureuser"
    ssh_key {
      key_data = var.ssh_public_key
    }
  }

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  ingress_application_gateway {
    gateway_id = var.app_gateway_id
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
  }
}
