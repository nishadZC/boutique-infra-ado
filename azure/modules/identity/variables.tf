variable "prefix" {
  description = "Prefix for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Location for resources"
  type        = string
}

variable "oidc_issuer_url" {
  description = "The OIDC Issuer URL for the AKS cluster"
  type        = string
}

variable "key_vault_id" {
  description = "The ID of the Key Vault to grant access to"
  type        = string
}

variable "tenant_id" {
  description = "The Azure AD Tenant ID"
  type        = string
}


variable "app_gateway_id" {
  description = "The ID of the Application Gateway"
  type        = string
}

variable "appgw_subnet_id" {
  description = "The ID of the App Gateway Subnet"
  type        = string
}

variable "resource_group_id" {
  description = "The ID of the Resource Group"
  type        = string
}

# Non-prod ACR: dev, qa, staging pull from here
variable "shared_acr_id" {
  description = "The ID of the shared (non-prod) ACR. Used by dev/qa/staging."
  type        = string
  default     = null
}

# Prod ACR: prod environment pulls exclusively from here
# Leave null for non-prod environments
variable "prod_acr_id" {
  description = "The ID of the prod-only ACR. If set, AcrPull is granted here instead of shared_acr_id."
  type        = string
  default     = null
}

variable "ingress_application_gateway_identity" {
  description = "The principal ID of the AGIC identity"
  type        = string
}

variable "kubelet_identity_object_id" {
  description = "The principal ID of the kubelet identity"
  type        = string
}
