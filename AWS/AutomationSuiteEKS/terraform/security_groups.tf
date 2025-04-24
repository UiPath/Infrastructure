/**
 * Security Groups Terraform Configuration
  * - Creates security groups for various services
  * - Configurable ingress and egress rules
  */

module "db_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name   = "${var.tag_prefix}${var.rds_instance_name}"
  vpc_id = module.vpc.vpc_id

  # Ingress rules
  ingress_with_cidr_blocks = [
    for subnet in module.vpc.private_subnets_cidr_blocks : {
      description = "Allow SQL Server access from private subnets"
      from_port   = 1433
      to_port     = 1433
      protocol    = "tcp"
      cidr_blocks = subnet
    }
  ]

  tags = var.tags
}
