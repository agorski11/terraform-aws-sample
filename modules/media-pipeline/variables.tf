variable "name" {
  description = "Prefix for resource names, e.g. app-dev."
  type        = string
}

variable "min_confidence" {
  description = "Rekognition moderation confidence floor, 0 to 100."
  type        = number
  default     = 60
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
