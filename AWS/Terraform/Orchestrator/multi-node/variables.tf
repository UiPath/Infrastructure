
## Provider Variables ##
### AWS Region ###
variable "aws_region" {
  description = "The region for deployment"
  default     = "eu-west-2"
}
### AWS Access Key ###
variable "access_key" {
  default = "SAGHGFDDSAFASFGFDGFA"
}
### AWS Secret Access Key ###
variable "secret_key" {
  default = "+FSAFDGDFSAFGFDFASFFSAFGWEQEWQR+23432EFFG"
}
### AWS SSH KEY ###
variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."

  default = {
    "us-east-1" = "ssh_key"
    "eu-west-2" = "ssh_key"
  }
}

##### Script Related Resources #####

#### Orchestrator Instance type ####
variable "aws_app_instance_type" {
  default = "m4.large"
}

## Set Initial Windows Administrator Password ##
variable "admin_password" {
  description = "Windows Administrator password to login as."
  default     = "Q123!w3s0m3Orch35tr4t0r"
}

variable "orchestrator_password" {
  description = "Orchestrator Administrator password to login as."
  default     = "123456@4dmin"
}

variable "orchestrator_passphrase" {
  description = "Orchestrator Passphrase in order to generate NuGet API keys, App encryption key and machine keys."
  default     = "Aw3s0m3Orch35tr4t0r"
}

variable "orchestrator_license" {
  description = "Orchestrator license code"
  default     = "DSGFSFGAGEHTERSEGW$%^%YHFDHDFHTTYJTKDGVXCFHGDSFSHJHMHKDGDFHYHFDHDFHTTYJTKDGVXCFHGDSFSHJHMHKDGDFHYHFDHDFHTTYJTKDGVXCFHGDSFSHJHMHKDGDFH+ADAAdwBvACEAJwAgADAAKAA="
}

variable "orchestrator_versions" {
  # "19.4.4" 
  # "19.4.3" 
  # "19.4.2"
  # "18.4.6"
  # "18.4.5"
  # "18.4.4"
  # "18.4.3"
  # "18.4.2"
  # "18.4.1"
  default = "19.10.15"

}

######## High Availability Add-on ######
variable "haa-user" {
  description = "High Availability Add-on username. Type email."
  default = "test@corp.com"
}

variable "haa-password" {
  description = "High Availability Add-on username password."
  default = "123456"
}

variable "haa-license" {
  description = "High Availability Add-on license key."
  default = "2353tgewsdfweg34t342rftg23g2g23t2r32r2353tgewsdfweg34t342rftg23g2g23t2r32r2353tgewsdfweg34t342rftg23g2g23t2r32r2353tgewsdfweg34t342rftg23g2g23t2r32r"
}

########  RDS DB #########
# Change default value to yes if you don't have an existing SQL server or if you want to create a RDS DB
variable "newSQL" {
  description = "Provision new RDS DB"
  default     = "no"
}

# Database username
variable "db_username" {
  description = "RDS master user name"
  default     = "devtestaws"
}

# Database username password, avoid using '/', '\"', or '@' 
variable "db_password" {
  description = "RDS Master Password must be at least eight characters long, as in 'mypassword'. Can be any printable ASCII character except '/', '\"', or '@' "
  default     = "!Aw3s0m3Orch35tr4t0r"
}

# Database name
variable "db_name" {
  description = "RDS database name"
  default     = "awstest"
}

# If you have an existing SQL and want to use it for Orchestrator DB, then change to the FQDN of that SQL. Example on Azure : sqlserver.database.windows.net
variable "sql_srv" {
  description = "SQL Server"
  default     = "awdevstest.database.com"
}


# The allocated storage in gigabytes.
variable "rds_allocated_storage" {
  default = "100"
}

# The instance type of the RDS instance.
variable "rds_instance_class" {
  default = "db.m4.large"
}

# Specifies if the RDS instance is multi-AZ.
variable "rds_multi_az" {
  default = "false"
}

# Determines whether a final DB snapshot is created before the DB instance is deleted.
variable "skip_final_snapshot" {
  type    = "string"
  default = "true"
}

#  Examples:
#  1. Get the second az in singapore:
#     "${element(var.aws_availability_zones['ap-southeast-1'], 0)}"


#  Availability zones for each region
variable "aws_availability_zones" {
  default = {
    #  N. Virginia
    us-east-1 = [
      "us-east-1a",
      "us-east-1b",
      "us-east-1c",
      "us-east-1d",
      "us-east-1e",
      "us-east-1f"
    ]
    #  Ohio
    us-east-2 = [
      "us-east-2a",
      "us-east-2b",
      "us-east-2c",
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
  default = "dev"
}

### FileGateWay Vars ###
variable "application" {
  default = "UiPath_OrchestratorStack"
}

variable "role" {
  default = "s3pol"
}

### S3 Bucket ###

variable "s3BucketName" {
  default = "tftestbucketorchestrator"
}

## Server Instances ##
# The count of Orchestrator instances in the ASG
variable "instance_count" {
  default = 1
}


### Certificate vars ###
# Existing domain in route53
variable "domain" {
  description = "The domain to use to host the project. This should already exist as a hosted zone in Route 53."
  default     = "corp.com"
}

# Subdomain will be created
variable "subdomain" {
  description = "The subdomain to use to host the project."
  default     = "elb"
}

# If you have an existing Certificate for the domain used in ALB (wildcard certificate), you can use that.
variable "certificate_arn" {
  description = "Certificate ARN in case you have an existing certificate."
  default     = ""
}

### Associate public IP to EC2 instances ###
variable "associate_public_ip_address" {
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
  description = "Security Group cidr block. Example: 10.10.0.0/16"
  default     = "0.0.0.0/0"
}
