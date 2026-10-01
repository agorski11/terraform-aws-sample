variable "name" {
  description = "Prefix for resource names, e.g. app-dev."
  type        = string
}

variable "domain_name" {
  description = "Optional custom domain. Leave null to use the cloudfront.net hostname."
  type        = string
  default     = null
}

variable "acm_certificate_arn" {
  description = "ACM certificate in us-east-1 covering domain_name. Required when domain_name is set."
  type        = string
  default     = null
}

variable "route53_zone_id" {
  description = "Hosted zone for the alias record. Required when domain_name is set."
  type        = string
  default     = null
}

variable "price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "tags" {
  type    = map(string)
  default = {}
}
