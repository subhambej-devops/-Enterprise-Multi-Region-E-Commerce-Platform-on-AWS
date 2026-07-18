data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "${var.project_name}-${var.environment}"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

module "network" {
  source = "../../modules/network"

  name             = local.name
  cidr             = "10.20.0.0/16"
  azs              = local.azs
  public_subnets   = ["10.20.0.0/20", "10.20.16.0/20", "10.20.32.0/20"]
  private_subnets  = ["10.20.48.0/20", "10.20.64.0/20", "10.20.80.0/20"]
  database_subnets = ["10.20.96.0/20", "10.20.112.0/20", "10.20.128.0/20"]
  tags             = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  name                                 = local.name
  cluster_version                      = var.cluster_version
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  vpc_id                               = module.network.vpc_id
  private_subnet_ids                   = module.network.private_subnet_ids
  admin_role_arns                      = var.admin_role_arns
  min_size                             = 3
  desired_size                         = 4
  max_size                             = 20
  tags                                 = local.common_tags
}

module "data" {
  source = "../../modules/data"

  name                       = local.name
  vpc_id                     = module.network.vpc_id
  database_subnet_ids        = module.network.database_subnet_ids
  private_subnet_ids         = module.network.private_subnet_ids
  allowed_security_group_ids = [module.eks.node_security_group_id]
  db_instance_count          = 2
  tags                       = local.common_tags
}
