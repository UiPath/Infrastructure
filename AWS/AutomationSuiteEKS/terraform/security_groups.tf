/**
 * Security Groups Terraform Configuration
  * - Creates security groups for various services
  * - Configurable ingress and egress rules
  */


# RDS
module "db_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name   = "${var.tag_prefix}${var.rds_instance_name}"
  vpc_id = module.vpc.vpc_id

  # Ingress rules
  ingress_with_cidr_blocks = [
    {
      description = "Allow private subnets to access RDS"
      from_port   = var.rds_port
      to_port     = var.rds_port
      protocol    = "tcp"
      cidr_blocks = join(",", module.vpc.private_subnets_cidr_blocks)
    }
  ]

  tags = var.tags
}

# Elasticache
module "elasticache_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name   = "${var.tag_prefix}${var.elasticache_cluster_name}"
  vpc_id = module.vpc.vpc_id

  # Ingress rules
  ingress_with_cidr_blocks = [{
    description = "Allow private subnets to access Elasticache"
    from_port   = var.elasticache_port
    to_port     = var.elasticache_port
    protocol    = "tcp"
    cidr_blocks = join(",", module.vpc.private_subnets_cidr_blocks)
  }]

  tags = var.tags
}

# EKS worker nodes
# module "eks_worker_sg" {
#   source  = "terraform-aws-modules/security-group/aws"
#   version = "~> 5.0"

#   name   = "${var.tag_prefix}${var.eks_cluster_name}-worker-nodes"
#   vpc_id = module.vpc.vpc_id

#   # Ingress rules
#   ingress_with_cidr_blocks = [
#     for subnet in module.vpc.private_subnets_cidr_blocks : {
#       description = "Allow private subnets to access EKS worker nodes"
#       from_port   = var.eks_worker_node_port
#       to_port     = var.eks_worker_node_port
#       protocol    = "tcp"
#       cidr_blocks = subnet
#     }
#   ]

#   tags = var.tags
# }
