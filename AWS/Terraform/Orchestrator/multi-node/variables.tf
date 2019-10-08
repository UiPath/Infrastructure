
## Provider Variables ##
### AWS Region ###
variable "aws_region" {
  description = "The region for UiPath Orchestrator deployment."
  default     = "eu-west-2"
}
### AWS Access Key ###
variable "access_key" {
  description = "AWS Access Key."
  default = "SAGFGDGVGDBXCVER"
}
### AWS Secret Access Key ###
variable "secret_key" {
  description = "AWS Secret Access Key."
  default = "+SAGFGDGVGDBXCVERSAGFGDGVGDBXCVER=="
}
### AWS SSH KEY ###
variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
  default = {
    "us-east-1" = "AWS_Existing_key"
    "eu-west-2" = "AWS_Existing_key"
  }
}

##### Script Related Resources #####

#### Orchestrator Instance type ####
variable "aws_app_instance_type" {
  description = "Orchestrator Instance type."
  default = "m4.large"
}

## Set Initial Windows Administrator Password ##
variable "admin_password" {
  description = "Windows Administrator password used to login in the provisioned VMs. In the data-templates.tf you can remove the blocks which set the custom password (check for ### remove this if you don't want to setup a password for local admin account ###)"
  default     = "WinP@55!"
}

variable "orchestrator_password" {
  description = "Orchestrator Administrator password to login in Default and Host Tennant."
  default     = "0rCh35Tr@tor!"
}

variable "orchestrator_passphrase" {
  description = "Orchestrator Passphrase in order to generate NuGet API keys, App encryption key and machine keys."
  default     = "2Custom5P@ssPh@se"
}

variable "orchestrator_license" {
  description = "Orchestrator license code. The license created with regutil."
  default     = "TheLicenseCreatedwithRegUtil"
}

variable "orchestrator_versions" {
  description = "Orchestrator Version."
  # "19.4.4" 
  # "19.4.3" 
  # "19.4.2"
  # "18.4.6"
  # "18.4.5"
  # "18.4.4"
  # "18.4.3"
  # "18.4.2"
  # "18.4.1"
  default = "19.4.4"

}

######## ElastiCache - REDIS ######
variable "redis_instance_type" {
  description = "ElastiCache - Redis instance type size."
  default = "cache.m4.large"
}

variable "elasticache" {
  description = "Tag name of the ElastiCache - Redis."
  default = "UiPath-Redis"
}

########  RDS DB #########
# Change default value to yes if you don't have an existing SQL server or if you want to create a RDS DB
variable "newSQL" {
  description = "Provision new RDS DB. Change default value from no to yes if you don't have an existing SQL server and you want to create a new RDS DB."
  default     = "no"
}

# Database username
variable "db_username" {
  description = "RDS master user name or username of the existing database."
  default     = "devawsdb"
}

# Database username password, avoid using '/', '\"', or '@' 
variable "db_password" {
  description = "Existing Database username password or create a password for the RDS. RDS Master Password must be at least eight characters long, as in 'mypassword'. Can be any printable ASCII character except '/', '\"', or '@'."
  default     = "!vfdgva%gsd"
}

# Database name
variable "db_name" {
  description = "RDS database name or the name of an existing database."
  default     = "awstest"
}

# If you have an existing SQL and want to use it for Orchestrator DB, then change to the FQDN of that SQL. Example on Azure : sqlserver.database.windows.net
variable "sql_srv" {
  description = "SQL Server FQDN if you have an existing SQL server."
  default     = "amazontest.database.windows.net"
}


# The allocated storage in gigabytes.
variable "rds_allocated_storage" {
  description = "Allocated storage (in GB) for the RDS instance."
  default = "100"
}

# The instance size type of the RDS instance.
variable "rds_instance_class" {
  description = "Instance size type of the RDS instance."
  default = "db.m4.large"
}

# True if the RDS instance is multi-AZ.
variable "rds_multi_az" {
  description = "True if the RDS instance is multi-AZ."
  default = "false"
}

# Determines whether a final DB snapshot is created before the DB instance is deleted.
variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted."
  type    = "string"
  default = "true"
}

#  Examples:
#  1. Get the second az in singapore:
#     "${element(var.aws_availability_zones['ap-southeast-1'], 0)}"


#  Availability zones for each region
variable "aws_availability_zones" {
  description = "Availability zones for each region."
  default = {
    #  N. Virginia
    us-east-1 = [
      "eu-east-1a",
      "eu-east-1b",
      "eu-east-1c",
      "eu-east-1d",
      "eu-east-1e",
      "eu-east-1f"
    ]
    #  Ohio
    us-east-2 = [
      "eu-east-2a",
      "eu-east-2b",
      "eu-east-2c",
    ]
    #  N. California
    us-west-1 = [
      "us-west-1a",
      "us-west-1b",
      "us-west-1c",
    ]
    #  Oregon
    us-west-2 = [
      "us-west-2a",
      "us-west-2b",
      "us-west-2c",
    ]
    #  Mumbai
    ap-south-1 = [
      "ap-south-1a",
      "ap-south-1b",
    ]
    #  Seoul
    ap-northeast-2 = [
      "ap-northeast-2a",
      "ap-northeast-2b",
    ]
    #  Singapore
    ap-southeast-1 = [
      "ap-southeast-1a",
      "ap-southeast-1b",
      "ap-southeast-1c",
    ]
    #  Sydney
    ap-southeast-2 = [
      "ap-southeast-2a",
      "ap-southeast-2b",
      "ap-southeast-2c",
    ]
    #  Tokyo (4)
    ap-northeast-1 = [
      "ap-northeast-1a",
      "ap-northeast-1b",
      "ap-northeast-1c",
    ]
    #  Osaka-Local (1)
    #  Central
    ca-central-1 = [
      "ca-central-1a",
      "ca-central-1b",
    ]
    #  Beijing (2)
    #  Ningxia (2)

    #  Frankfurt (3)
    eu-central-1 = [
      "eu-central-1a",
      "eu-central-1b",
      "eu-central-1c",
    ]
    #  Ireland (3)
    eu-west-1 = [
      "eu-west-1a",
      "eu-west-1b",
      "eu-west-1c",
    ]
    #  London (3)
    eu-west-2 = [
      "eu-west-2a",
      "eu-west-2b",
      "eu-west-2c",
    ]
    #  Paris (3)
    eu-west-3 = [
      "eu-west-3a",
      "eu-west-3b",
      "eu-west-3c",
    ]
    #  São Paulo (3)
    sa-east-1 = [
      "sa-east-1a",
      "sa-east-1b",
      "sa-east-1c",
    ]
    #  AWS GovCloud (US-West) (2)
  }
}


# Environment name, used as prefix to name resources.
variable "environment" {
  description = "Environment name, used as prefix to tag Name of the resources."
  default = "dev"
}

### FileGateWay Vars ###
variable "application" {
  description = "Application stack name, used as prefix to tag Name of the resources."
  default = "UiPath_OrchestratorStack"
}

variable "role" {
  description = "Role name for S3 Bucket."
  default = "s3"
}

### S3 Bucket ###

variable "s3BucketName" {
  default = "New S3 Bucket Name."
  default = "tftestorchestrator"
}

## Server Instances ##
# The count of Orchestrator instances in the ASG
variable "instance_count" {
  description = "The desired count of the Orchestrator instances in the ASG."
  default = 1
}


### Certificate vars ###
# Existing domain in route53
variable "domain" {
  description = "The domain to use to host the project. This should exist as a hosted zone in Route 53."
  default     = "existing-domain-in-r53.com"
}

# New subdomain used for ALB.
variable "subdomain" {
  description = "New subdomain used for ALB."
  default     = "alb-orchestrator"
}

# If you have an existing Certificate for the domain used in ALB (wildcard certificate), you can use that.
variable "certificate_arn" {
  description = "Certificate ARN in case you have an existing certificate (wildcard certificate)."
  default     = ""
}

### Associate public IP to EC2 instances ###
variable "associate_public_ip_address" {
  description = "Associate public IP to EC2 Orchestrator instances."
  default = "false"
}




### VPC + CIDR block + Security Group###
# variable "vpc" {
#     type    = "map"
#     default = {
#         "tag"         = "UipathStack-VPC"
#         "cidr_block"  = "10.0.0.0/20"
#         "subnet_bits" = "4"
#     }
# }

variable "cidr_block" {
  type        = "string"
  description = "VPC cidr block. Example: 10.10.0.0/16"
  default     = "10.0.0.0/16"
}

### You can add your CIDR block in order to access the resources. 
### Also you can modify security.tf as per your needs, but for the port 80 you must whitelist your CIDR in order to create the FileGateway.
### Only 80 and 443 must have access to the internet if you want to access the Orchestrator via the Internet. 
variable "security_cidr_block" {
  type        = "string"
  description = "Security Group cidr block. Example: 10.10.0.0/16. Also you can modify security.tf as per your needs, but for the port 80 you must whitelist your CIDR in order to create the FileGateway. Only 80 and 443 must have access to the internet if you want to access the Orchestrator via the Internet."
  default     = "0.0.0.0/0"
}