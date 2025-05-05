/**
 * EC2 Terraform Configuration (Optional)
 * - Creates EC2 instance with specified AMI and intance type
 * - Default AMI is windows server 2022 and its access is only allowed from the specified IP and/or an IP address where the terraform is executed
 * - By default, the following software is installed:
 *  - UiPath Studio, Rorbots, MS edge and MS SQL Server Management Studio
 * - This code is using terraform-aws-modules/ec2-instance/aws module (https://github.com/terraform-aws-modules/terraform-aws-ec2-instance)
 */

data "aws_ami" "latest_windows" {
  most_recent = true

  owners = [var.ec2_ami_owner]

  filter {
    name   = "name"
    values = [var.ec2_ami_prefix]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

locals {
  # Get the latest AMI ID for Windows Server 2022
  ec2_subnet_id = var.is_ec2_public ? module.vpc.public_subnets[0] : local.private_subnet_list[0].id
}

# Create key pair for EC2 instance if not specified
resource "tls_private_key" "ec2_key" {
  count     = var.ec2_key_name == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key" {
  count      = var.ec2_key_name == "" ? 1 : 0
  key_name   = "${var.tag_prefix}${var.ec2_instance_name}"
  public_key = tls_private_key.ec2_key[0].public_key_openssh
  tags       = merge({ "Name" = "${var.tag_prefix}${var.ec2_instance_name}" }, var.tags)
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"
  create  = var.create_ec2_instance

  name               = var.ec2_instance_name
  ami                = data.aws_ami.latest_windows.id
  ignore_ami_changes = true # Ignore changes to the AMI ID
  instance_type      = var.ec2_instance_type
  key_name           = var.ec2_key_name == "" ? aws_key_pair.ec2_key[0].key_name : var.ec2_key_name

  # VPC and Subnet settings
  vpc_security_group_ids = [module.ec2_sg.security_group_id]
  subnet_id              = local.ec2_subnet_id
  create_eip             = var.is_ec2_public ? true : false

  # EBS settings
  root_block_device = [
    {
      volume_size           = var.ec2_volume_size
      delete_on_termination = true
      volume_type           = "gp3"
      encrypted             = true
    }
  ]
  # User data
  user_data_base64 = var.use_ec2_user_data ? base64encode(file("${path.module}/template/${var.ec2_user_data_name}")) : null
  # Password
  get_password_data = var.get_ec2_password

  # Tags
  tags = var.tags
}

output "ec2_instance_id" {
  description = "The ID of the EC2 instance"
  value       = module.ec2_instance.id
}

output "ec2_instance_public_ip" {
  description = "The public IP of the EC2 instance"
  value       = module.ec2_instance.public_ip
}

output "ec2_instance_private_ip" {
  description = "The private IP of the EC2 instance"
  value       = module.ec2_instance.private_ip
}

output "ec2_instance_password" {
  description = "The password for the EC2 instance. Only works if the key pair is created by this module."
  value       = var.ec2_key_name == "" && var.get_ec2_password == true ? "${rsadecrypt(module.ec2_instance.password_data, tls_private_key.ec2_key[0].private_key_pem)}" : null
  sensitive   = true
}
