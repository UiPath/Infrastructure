/**
 * Security Groups Terraform Configuration
  * - Creates security groups for various services
  * - Configurable ingress and egress rules
  * - This code is using terraform-aws-modules/security-group/aws module (https://github.com/terraform-aws-modules/terraform-aws-security-group)
  */

# Get the current public IP address
data "http" "current_ip" {
  url = "https://checkip.amazonaws.com/"
}

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

# EC2
module "ec2_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"
  create  = var.create_ec2_instance

  name   = "${var.tag_prefix}${var.ec2_instance_name}"
  vpc_id = module.vpc.vpc_id

  # Ingress rules
  ingress_with_cidr_blocks = [
    {
      description = "Allow RDP access to EC2 instance"
      from_port   = var.ec2_port
      to_port     = var.ec2_port
      protocol    = "tcp"
      cidr_blocks = length(var.ec2_allowed_cidr_blocks) == 0 ? "${chomp(data.http.current_ip.response_body)}/32" : var.ec2_allowed_cidr_blocks
    }
  ]
  # Egress rules
  egress_with_cidr_blocks = [
    {
      description = "Allow all outbound traffic from EC2 instance"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  tags = var.tags
}
