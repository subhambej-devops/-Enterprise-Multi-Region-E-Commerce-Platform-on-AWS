variable "project_name" {
  description = "Project name."
  type        = string
  default     = "enterprise-commerce"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "secondary"
}

variable "region" {
  description = "AWS region for this stack."
  type        = string
  default     = "us-west-2"
}

variable "cluster_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.35"
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS API endpoint is reachable from public networks."
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint when enabled."
  type        = list(string)
  default     = []
}

variable "admin_role_arns" {
  description = "IAM roles with EKS cluster admin access."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
}
