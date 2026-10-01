variable "name" {
  description = "Prefix for resource names, e.g. app-dev."
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR."
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Availability zones to spread subnets across."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "Use 2 or 3 AZs."
  }
}

variable "single_nat_gateway" {
  description = "One shared NAT gateway (cheap, dev) or one per AZ (resilient, prod)."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
