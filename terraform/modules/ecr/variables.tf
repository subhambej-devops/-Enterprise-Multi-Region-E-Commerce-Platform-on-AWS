variable "name" {
  description = "Name prefix for ECR repositories."
  type        = string
}

variable "services" {
  description = "Service names that receive ECR repositories."
  type        = list(string)
}

variable "replication_destinations" {
  description = "Regions and registries used for ECR cross-region replication."
  type = list(object({
    region      = string
    registry_id = string
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

