output "cluster_name" {
  description = "Secondary EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Secondary EKS API endpoint."
  value       = module.eks.cluster_endpoint
}

output "postgres_endpoint" {
  description = "Secondary Aurora writer endpoint."
  value       = module.data.postgres_endpoint
}

output "redis_primary_endpoint" {
  description = "Secondary Redis endpoint."
  value       = module.data.redis_primary_endpoint
}

output "assets_bucket_name" {
  description = "Secondary assets bucket."
  value       = module.data.assets_bucket_name
}

