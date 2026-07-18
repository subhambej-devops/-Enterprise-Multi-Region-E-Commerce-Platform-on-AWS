variable "name" {
  description = "Name prefix for edge resources."
  type        = string
}

variable "domain_name" {
  description = "Application DNS name."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9.-]+$", var.domain_name)) && length(var.domain_name) > 0
    error_message = "domain_name must be a non-empty DNS name."
  }
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID."
  type        = string

  validation {
    condition     = length(var.hosted_zone_id) > 0
    error_message = "hosted_zone_id must not be empty."
  }
}

variable "certificate_arn" {
  description = "ACM certificate ARN in us-east-1 for CloudFront."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-zA-Z-]*:acm:us-east-1:[0-9]{12}:certificate/.+", var.certificate_arn))
    error_message = "certificate_arn must be an ACM certificate ARN from us-east-1."
  }
}

variable "primary_origin_domain_name" {
  description = "Primary region ingress DNS name."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9.-]+$", var.primary_origin_domain_name)) && length(var.primary_origin_domain_name) > 0
    error_message = "primary_origin_domain_name must be a non-empty DNS name without a protocol."
  }
}

variable "secondary_origin_domain_name" {
  description = "Secondary region ingress DNS name."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9.-]+$", var.secondary_origin_domain_name)) && length(var.secondary_origin_domain_name) > 0
    error_message = "secondary_origin_domain_name must be a non-empty DNS name without a protocol."
  }
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
