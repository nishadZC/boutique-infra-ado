variable "maps_account_name" {
  description = "The name of the Azure Maps Account."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "sku_name" {
  description = "The SKU of the Azure Maps Account."
  type        = string
  default     = "S0"
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}
