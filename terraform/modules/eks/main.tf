resource "aws_kms_key" "eks" {
  description             = "KMS key for ${var.name} EKS secrets encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.name
  cluster_version = var.cluster_version

  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true

  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    general = {
      name           = "${var.name}-general"
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"
      min_size       = var.min_size
      max_size       = var.max_size
      desired_size   = var.desired_size

      labels = {
        workload = "general"
      }

      update_config = {
        max_unavailable_percentage = 25
      }
    }

    spot = {
      name           = "${var.name}-spot"
      instance_types = var.node_instance_types
      capacity_type  = "SPOT"
      min_size       = 0
      max_size       = var.max_size
      desired_size   = 2

      labels = {
        workload = "stateless"
      }

      taints = {
        spot = {
          key    = "capacity"
          value  = "spot"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  access_entries = {
    for arn in var.admin_role_arns : replace(arn, ":", "_") => {
      principal_arn = arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Allow nodes to communicate with each other"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  tags = var.tags
}
