/**
 * VPC Terraform Configuration
 * - Creates a new VPC with public and private subnets
 * - Configurable NAT Gateway deployment (single or one per AZ)
 * - Optional secondary CIDR block support
 */

# Local variable for AZ calculation if none provided
locals {
  # Determine AZs - use provided list or fetch from AWS (limited to 3)
  azs = length(data.aws_availability_zones.available.names) > 3 ? slice(data.aws_availability_zones.available.names, 0, 3) : data.aws_availability_zones.available.names


  # Subnet calculations for primary CIDR
  # Public subnets use the first set of /24 blocks (0, 1, 2, etc.)
  public_subnets = [for i in range(length(local.azs)) : cidrsubnet(var.vpc_cidr, 8, i)]

  # Private subnets use the next set of /24 blocks (10, 11, 12, etc.)
  private_subnets = [for i in range(length(local.azs)) : cidrsubnet(var.vpc_cidr, 8, i + 10)]

  # Database subnets use the next set of /24 blocks (20, 21, 22, etc.)
  database_subnets = [for i in range(length(local.azs)) : cidrsubnet(var.vpc_cidr, 8, i + 20)]

  # Subnet calculations for secondary CIDR (if enabled)
  # In the secondary CIDR, each subnet uses a /21 block to accommodate more IPs
  secondary_private_subnets = var.enable_secondary_cidr ? [
    for i in range(length(local.azs)) : cidrsubnet(var.secondary_vpc_cidr, 5, i)
  ] : []

  # Combine all subnets if secondary CIDR is enabled
  all_private_subnets = var.enable_secondary_cidr ? concat(local.private_subnets, local.secondary_private_subnets) : local.private_subnets

  # Create a list of primary subnet ids, subnets and their azs
  private_subnet_list = [
    for s in data.aws_subnet.private :
    {
      id   = s.id
      az   = s.availability_zone
      cidr = s.cidr_block
    }
    if contains(local.private_subnets, s.cidr_block)
  ]
  # Create a list of secondary subnet ids, subnets and their azs
  secondary_private_subnet_list = [
    for s in data.aws_subnet.private :
    {
      id   = s.id
      az   = s.availability_zone
      cidr = s.cidr_block
    }
    if contains(local.secondary_private_subnets, s.cidr_block)
  ]
}

# Get available AZs
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Get subnet ids
data "aws_subnet" "private" {
  for_each   = toset(local.all_private_subnets)
  cidr_block = each.key
  vpc_id     = module.vpc.vpc_id
  depends_on = [module.vpc]
}


# Create VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  # Secondary CIDR block (if enabled)
  secondary_cidr_blocks = var.enable_secondary_cidr ? [var.secondary_vpc_cidr] : []

  # Availability Zones and subnets
  azs              = local.azs
  public_subnets   = local.public_subnets
  private_subnets  = local.all_private_subnets
  database_subnets = local.database_subnets

  create_database_subnet_group = true

  # NAT Gateway configuration
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.enable_nat_gateway && !var.single_nat_gateway

  # DNS settings
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPN Gateway
  enable_vpn_gateway = var.enable_vpn_gateway

  # Tags
  tags = var.tags

  # Subnet specific tags
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks of the VPC"
  value       = module.vpc.vpc_secondary_cidr_blocks
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

output "private_subnet_list" {
  description = "List of private subnets with their IDs, availability zones, and CIDR blocks"
  value       = local.private_subnet_list
}

output "secondary_private_subnet_list" {
  description = "List of secondary private subnets with their IDs, availability zones, and CIDR blocks"
  value       = local.secondary_private_subnet_list
}

