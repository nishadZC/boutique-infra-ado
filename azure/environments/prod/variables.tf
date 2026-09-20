variable "location" {
  type = string
  validation {
    condition     = contains(["East US", "East US 2", "West US", "North Europe", "West Europe", "Central India"], var.location)
    error_message = "The location must be one of: East US, East US 2, West US, North Europe, West Europe, Central India."
  }
}

variable "prefix" {
  type = string
  validation {
    condition     = length(var.prefix) <= 15
    error_message = "The prefix must be 15 characters or less to prevent resource name length issues."
  }
}

variable "db_password" {
  type      = string
  sensitive = true
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "The database password must be at least 8 characters long."
  }
}

variable "vnet_address_space" {
  type = list(string)
}

variable "aks_subnet_prefix" {
  type = string
}

variable "appgw_subnet_prefix" {
  type = string
}

variable "postgres_subnet_prefix" {
  type = string
}

variable "pagerduty_key" {
  type      = string
  sensitive = true
}

variable "cloudinary_cloud_name" {
  type      = string
  sensitive = true
}

variable "cloudinary_api_key" {
  type      = string
  sensitive = true
}

variable "cloudinary_api_secret" {
  type      = string
  sensitive = true
}

variable "google_client_id" {
  type      = string
  sensitive = true
}

variable "azure_maps_subscription_key" {
  type      = string
  sensitive = true
}

variable "razorpay_key_id" {
  type      = string
  sensitive = true
}

variable "razorpay_key_secret" {
  type      = string
  sensitive = true
}


variable "ssh_public_key" {
  type        = string
  description = "SSH public key for AKS nodes"
}
