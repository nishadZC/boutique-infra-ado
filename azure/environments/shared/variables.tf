variable "location" {
  type = string
  validation {
    condition     = contains(["Canada Central", "East US", "East US 2", "West US", "North Europe", "West Europe", "Central India"], var.location)
    error_message = "The location must be one of: Canada Central, East US, East US 2, West US, North Europe, West Europe, Central India."
  }
}

variable "prefix" {
  type = string
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

# SSH: leave empty to rely on Azure Bastion (recommended)
variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "Direct SSH CIDRs. Leave empty to use Azure Bastion exclusively (recommended)."
  default     = []
}

# SonarQube web UI on port 9000 — must be restricted to known CIDRs
variable "allowed_web_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to access SonarQube port 9000. Set via Azure DevOps variable group."
}
