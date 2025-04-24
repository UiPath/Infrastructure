# Terraform Variables
# This file contains all variables used in the Terraform configuration


/**
  * General Variables
  * This file contains all general variables used in the Terraform configuration
 */

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
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

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
  default     = []
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
 * eks Configuration Variables
 * This file contains all variables related to eks configuration
 */

# variable "eks_cluster_name" {
#   description = "Name of the EKS cluster"
#   type        = string
#   default     = "main-eks-cluster"
# }

# variable "eks_cluster_version" {
#   description = "Version of the EKS cluster"
#   type        = string
#   default     = "1.31"
# }


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

variable "s3_cors_allowed_origins" {
  description = "Allowed origins for CORS configuration"
  type        = list(string)
  default     = ["*"]
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

variable "rds_subnet_group_name" {
  description = "Name of the RDS subnet group"
  type        = string
  default     = "main-rds-subnet-group"
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
