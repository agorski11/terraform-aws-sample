variable "project" {
  type = string
}

variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type = string
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "site_domain_name" {
  type    = string
  default = null
}

variable "site_acm_certificate_arn" {
  type    = string
  default = null
}

variable "route53_zone_id" {
  type    = string
  default = null
}

variable "moderation_min_confidence" {
  type    = number
  default = 60
}
