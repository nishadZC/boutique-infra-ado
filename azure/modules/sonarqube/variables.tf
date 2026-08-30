variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "vm_name" { type = string }
variable "subnet_id" { type = string }
variable "admin_username" { type = string }
variable "ssh_public_key" { type = string }

# Industry standard: SSH should go through Azure Bastion (already provisioned in network module)
# Only populate this if you need emergency direct SSH access from a known static IP
variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed direct SSH. Leave empty to rely solely on Azure Bastion (recommended)."
  default     = [] # Empty = no direct SSH, use Bastion
}

# Industry standard: restrict SonarQube web UI to known CIDRs (VPN/office/developer IPs)
variable "allowed_web_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to access SonarQube on port 9000. Restrict to team/VPN IPs."
  validation {
    condition     = length(var.allowed_web_cidrs) > 0
    error_message = "allowed_web_cidrs must contain at least one CIDR. Port 9000 must not be open to 0.0.0.0/0."
  }
}

variable "vm_size" {
  type        = string
  default     = "Standard_B2ps_v2"
  description = "The Azure VM size for the SonarQube instance."
}

variable "tags" {
  type    = map(string)
  default = {}
}
