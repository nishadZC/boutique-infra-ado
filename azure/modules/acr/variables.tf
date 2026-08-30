variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "acr_name" { type = string }
variable "sku" {
  type    = string
  default = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}
variable "tags" {
  type    = map(string)
  default = {}
}
