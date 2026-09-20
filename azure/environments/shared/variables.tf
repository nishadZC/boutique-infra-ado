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
