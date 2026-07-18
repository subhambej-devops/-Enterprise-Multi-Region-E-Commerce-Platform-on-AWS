variable "name" {
  description = "EKS cluster name."
  type        = string
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
  description = "CIDR blocks allowed to reach the public EKS API endpoint when public access is enabled."
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for worker nodes."
  type        = list(string)
}

variable "admin_role_arns" {
  description = "IAM role ARNs granted cluster admin access."
  type        = list(string)
  default     = []
}

variable "node_instance_types" {
  description = "EC2 instance types for managed node groups."
  type        = list(string)
  default     = ["m6i.large", "m6a.large"]
}

variable "min_size" {
  description = "Minimum managed node group size."
  type        = number
  default     = 3
}

variable "max_size" {
  description = "Maximum managed node group size."
  type        = number
  default     = 20
}

variable "desired_size" {
  description = "Desired managed node group size."
  type        = number
  default     = 6
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
