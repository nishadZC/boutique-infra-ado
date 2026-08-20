variable "location" {
  type    = string
  validation {
    condition     = contains(["Canada Central", "East US", "West US", "North Europe", "West Europe"], var.location)
    error_message = "The location must be one of: Canada Central, East US, West US, North Europe, West Europe."
  }
}

variable "prefix" {
  type    = string
  validation {
    condition     = length(var.prefix) <= 15
    error_message = "The prefix must be 15 characters or less to prevent resource name length issues."
  }
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

variable "vnet_address_space" {
  type = list(string)
}

variable "sonarqube_subnet_prefix" {
  type = string
}
