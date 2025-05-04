# Terraform Variables
# This file contains all variables used in the Terraform configuration


/**
  * General Variables
  * This file contains all general variables used in the Terraform configuration
 */

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = ""
}

variable "tag_prefix" {
  description = "(Optional) Prefix for all tags. Default is '' (empty string)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    CreatedBy   = "Terraform"
  }
}

variable "fqdn" {
  description = "Fully Qualified Domain Name (FQDN) for your Automaiton Suite without https. This is used for s3's cors configuration."
  type        = string
  default     = ""
}

/**
 * VPC Configuration Variables
 * This file contains all variables related to VPC configuration
 */

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "main-vpc"
}

variable "vpc_cidr" {
  description = "Primary CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_secondary_cidr" {
  description = "Whether to enable a secondary CIDR block"
  type        = bool
  default     = false
}

variable "secondary_vpc_cidr" {
  description = "Secondary CIDR block for the VPC (if enabled) - Using CGNAT range by default"
  type        = string
  default     = "100.64.0.0/16"
}

variable "single_nat_gateway" {
  description = "Whether to use a single NAT Gateway for all private subnets"
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Whether to enable NAT Gateway(s)"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Whether to create a VPN Gateway"
  type        = bool
  default     = false
}

/**
  * S3 Configuration Variables
  * This file contains all variables related to S3 configuration
  */

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = ""
}

variable "s3_force_destroy" {
  description = "Whether to force destroy the S3 bucket"
  type        = bool
  default     = true
}

/**
  * RDS Configuration Variables
  * This file contains all variables related to RDS configuration
  */

variable "rds_instance_name" {
  description = "Name of the RDS instance"
  type        = string
  default     = "main-mssql"
}

variable "rds_engine" {
  description = "Engine for the RDS instance. Supported values are sqlserver-se (standard) or sqlserver-ee (enterprise)"
  type        = string
  default     = "sqlserver-se"
}

variable "rds_engine_version" {
  description = "Engine version for the RDS instance"
  type        = string
  default     = "15.00"
}

variable "rds_instance_type" {
  description = "Instance type for the RDS instance. Default is db.m5.xlarge, but for production, it should be db.m5.2xlarge or other db instance types with 8 vCPU and 32GB memory"
  type        = string
  default     = "db.m5.xlarge"
}

variable "rds_storage_encrypted" {
  description = "Whether to enable storage encryption for the RDS instance"
  type        = bool
  default     = true
}

variable "rds_storage_size" {
  description = "Storage size for the RDS instance in GB"
  type        = number
  default     = 256
}

variable "rds_username" {
  description = "Username for the RDS instance"
  type        = string
  default     = "admin"
}

variable "rds_password" {
  description = "Password for the RDS instance"
  type        = string
  default     = ""
  sensitive   = true
}

variable "rds_port" {
  description = "Port for the RDS instance"
  type        = number
  default     = 1433
}

variable "rds_multi_az" {
  description = "Whether to enable Multi-AZ for the RDS instance"
  type        = bool
  default     = false
}

variable "rds_maintenance_window" {
  description = "Maintenance window for the RDS instance"
  type        = string
  default     = "Mon:00:00-Mon:03:00"
}

variable "rds_backup_window" {
  description = "Backup window for the RDS instance"
  type        = string
  default     = "03:00-06:00"
}

variable "rds_backup_retention_period" {
  description = "Backup retention period for the RDS instance in days"
  type        = number
  default     = 1
}

variable "rds_deletion_protection" {
  description = "Whether to enable deletion protection for the RDS instance"
  type        = bool
  default     = false
}

variable "rds_license_model" {
  description = "License model for the RDS instance. Default is license-included"
  type        = string
  default     = "license-included"
}

variable "rds_timezone" {
  description = "Timezone for the RDS instance"
  type        = string
  default     = "GMT Standard Time"
}

/**
 * Elasticache Configuration Variables
  * This file contains all variables related to Elasticache configuration
  */

variable "elasticache_cluster_name" {
  description = "Name of the Elasticache cluster"
  type        = string
  default     = "main-redis-cluster"
}

variable "elasticache_auth_token" {
  description = "Authentication token for the Elasticache cluster"
  type        = string
  default     = ""
  sensitive   = true
}

variable "elasticache_num_of_cache_clusters" {
  description = "Number of replicas for the Elasticache cluster"
  type        = number
  default     = 2
}

variable "elasticache_node_type" {
  description = "Node type for the Elasticache cluster"
  type        = string
  default     = "cache.t2.small"
}

variable "elasticache_engine_version" {
  description = "Engine version for the Elasticache cluster"
  type        = string
  default     = "7.1"
}

variable "elasticache_maintenance_window" {
  description = "Maintenance window for the Elasticache cluster"
  type        = string
  default     = "sun:00:00-sun:03:00"
}

variable "elasticache_port" {
  description = "Port for the Elasticache cluster"
  type        = number
  default     = 6379
}

variable "elasticache_parameter_group_name" {
  description = "Name of the Elasticache parameter group"
  type        = string
  default     = "default.redis7"
}

/**
 * eks Configuration Variables
 * This file contains all variables related to eks configuration
 */

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "main-eks-cluster"
}

variable "eks_cluster_version" {
  description = "Version of the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "enable_eks_public_access" {
  description = "Whether to enable public access to the EKS cluster"
  type        = bool
  default     = true
}

variable "eks_node_group_name" {
  description = "Name of the EKS node group"
  type        = string
  default     = "main-eks-node-group"
}

variable "eks_instance_type" {
  description = "Instance type for the main EKS node group"
  type        = string
  default     = "c6a.4xlarge"
}

variable "eks_node_max_pod" {
  description = "Maximum number of pods per node. This value varies on intance types, so for more details, refer to https://github.com/aws/amazon-vpc-cni-k8s/blob/master/misc/eni-max-pods.txt"
  type        = number
  default     = 234
}


/**
  * EC2 Configuration Variables
  * This file contains all variables related to EC2 configuration
  * By default, no EC2 instance is created
  */

variable "create_ec2_instance" {
  description = "Whether to create an EC2 instance"
  type        = bool
  default     = false
}

variable "ec2_instance_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "main-ec2-instance"
}

variable "ec2_ami_prefix" {
  description = "Prefix of AMI ID for the EC2 instance"
  type        = string
  default     = "Windows_Server-2022-English-Full-Base-*" # Windows Server 2022
}

variable "ec2_ami_owner" {
  description = "Owner of the AMI for the EC2 instance"
  type        = string
  default     = "amazon"
}

variable "ec2_instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
  default     = "t3.large"
}

variable "is_ec2_public" {
  description = "Whether the EC2 instance is public. By default, it is public. If set to false, it will be private."
  type        = bool
  default     = true
}

variable "ec2_volume_size" {
  description = "Volume size for the EC2 instance in GB"
  type        = number
  default     = 100
}

variable "ec2_port" {
  description = "Port for the EC2 instance. Default is 3389 (RDP)"
  type        = number
  default     = 3389
}

variable "ec2_allowed_cidr_blocks" {
  description = "Allowed CIDR blocks for the EC2 instance. If empty, it will only allow the IP address where the Terraform is executed."
  type        = string
  default     = ""
}

variable "use_ec2_user_data" {
  description = "Whether to use user data for the EC2 instance. By default, it is set to true."
  type        = bool
  default     = true
}

variable "ec2_user_data_name" {
  description = "Name of the user data file for the EC2 instance. By default, it is set to 'windows_user_data.tftpl', which installs Microsoft Edge and UiPath Studio."
  type        = string
  default     = "windows_user_data.tftpl"
}

variable "get_ec2_password" {
  description = "Whether to get the password for the EC2 instance. By default, it is set to false."
  type        = bool
  default     = false
}

variable "ec2_key_name" {
  description = "Name of the key pair for the EC2 instance. By default, it is set to 'main-key-pair'."
  type        = string
  default     = ""
}
