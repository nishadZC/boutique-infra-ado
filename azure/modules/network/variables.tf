variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region to deploy resources"
}

variable "vnet_name" {
  type        = string
  description = "Name of the virtual network"
}

variable "address_space" {
  type        = list(string)
  description = "The address space that is used the virtual network"
}

variable "aks_subnet_prefix" {
  type        = string
  description = "Address prefix for the AKS subnet"
}

variable "appgw_subnet_prefix" {
  type        = string
  description = "Address prefix for the Application Gateway subnet"
}

variable "postgres_subnet_prefix" {
  type        = string
  description = "Address prefix for the PostgreSQL subnet"
}

