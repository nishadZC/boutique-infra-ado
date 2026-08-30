variable "name" {
  description = "The name of the Resource Group"
  type        = string
}

variable "location" {
  description = "The Azure Region where the Resource Group should exist"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the Resource Group"
  type        = map(string)
  default     = {}
}
