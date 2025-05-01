/**
 * Elasticache Redis Terraform Configuration
  * - Creates a Redis cluster with specified node type and engine version
  * - Configurable number of replicas and cluster mode settings
  * - Optional parameter group for custom Redis settings
  */

module "elasticache" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "~> 1.5"

  # Cluster name and settings
  replication_group_id       = var.elasticache_cluster_name
  multi_az_enabled           = true
  auth_token                 = var.elasticache_auth_token
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  num_cache_clusters         = var.elasticache_num_of_cache_clusters

  # Cluster mode needs to be disabled
  cluster_mode = "disabled"

  engine_version = var.elasticache_engine_version
  node_type      = var.elasticache_node_type

  maintenance_window = var.elasticache_maintenance_window
  apply_immediately  = true

  # Security Group
  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.vpc.default_security_group_id, module.elasticache_sg.security_group_id]

  # Subnet Group
  subnet_ids = local.private_subnet_list.*.id

  # Parameter Group
  parameter_group_name = var.elasticache_parameter_group_name

  tags = var.tags
}


# Outputs
output "elasticache_primary_endpoint" {
  description = "The primary endpoint of the Elasticache cluster"
  value       = module.elasticache.replication_group_primary_endpoint_address
}

output "elasticache_auth_token" {
  description = "The authentication token for the Elasticache cluster"
  value       = var.elasticache_auth_token
  sensitive   = true
}

output "elasticache_port" {
  description = "The port for the Elasticache cluster"
  value       = var.elasticache_port
}
