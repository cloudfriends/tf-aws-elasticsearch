variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region"
}

variable "owner" {
  type        = string
  default     = ""
  description = "Namespace, which could be your organization name or abbreviation, e.g. 'rti' or 'ddoa'"
}

variable "env" {
  type        = string
  default     = ""
  description = "Environment, e.g. 'prod', 'staging', 'dev', 'pre-prod', 'UAT'"
}

variable "business_domain" {
  type        = string
  default     = ""
  description = "Business Domain , e.g. 'inventory', 'parts'"
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `namespace`, `environment`, `stage`, `name` and `attributes`"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags (e.g. `map('BusinessUnit','XYZ')`"
}
