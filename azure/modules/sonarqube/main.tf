resource "azurerm_public_ip" "sonar" {
  name                = "${var.vm_name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_security_group" "sonar" {
  name                = "${var.vm_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Industry standard: restrict SSH to known CIDRs (VPN/office), never 0.0.0.0/0
  dynamic "security_rule" {
    for_each = toset(var.allowed_ssh_cidrs)
    content {
      name                       = "AllowSSH-${replace(security_rule.value, "/", "-")}"
      priority                   = 1000 + index(var.allowed_ssh_cidrs, security_rule.value)
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = security_rule.value
      destination_address_prefix = "*"
    }
  }

  # Industry standard: restrict SonarQube web UI to known CIDRs, never 0.0.0.0/0
  dynamic "security_rule" {
    for_each = toset(var.allowed_web_cidrs)
    content {
      name                       = "AllowSonarWeb-${replace(security_rule.value, "/", "-")}"
      priority                   = 1100 + index(var.allowed_web_cidrs, security_rule.value)
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "9000"
      source_address_prefix      = security_rule.value
      destination_address_prefix = "*"
    }
  }

  # Deny all other inbound traffic (explicit deny-all is best practice)
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "sonar" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.sonar.id
  }
}

resource "azurerm_network_interface_security_group_association" "sonar" {
  network_interface_id      = azurerm_network_interface.sonar.id
  network_security_group_id = azurerm_network_security_group.sonar.id
}

resource "azurerm_linux_virtual_machine" "sonar" {
  name                = var.vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.sonar.id,
  ]

  # Industry standard: SSH key authentication only, no passwords
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  # Industry standard: disable password authentication explicitly
  disable_password_authentication = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-arm64"
    version   = "latest"
  }

  custom_data = filebase64("${path.module}/setup.sh")

  lifecycle {
    ignore_changes = [
      vm_agent_platform_updates_enabled,
    ]
  }
}
