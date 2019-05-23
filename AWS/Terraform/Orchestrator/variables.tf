## Provider Variables ##
variable "aws_region" {
  description = "The region for deployment"
  default     = "eu-west-2"
}

variable "access_key" {
  default = "access_key_from_AWS"
}

variable "secret_key" {
  default = "secret_key_from_AWS"
}

variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."

  default = {
    "us-east-1" = "ssh_key"
    "eu-west-2" = "ssh_key"
  }
}

## Microsoft Windows Server 2016 Base ##
variable "aws_w2016_std_amis" {
  default = {
    eu-west-2 = "ami-0f83d76c5da014440"
  }
}

variable "aws_app_instance_type" {
  default = "m4.large"
}

variable "aws_subnet_id" {
  default = {
    "us-east-1" = "subnet-xxxxxxxx"
    "us-west-2" = "subnet-xxxxxxxx"
    "eu-west-2" = "subnet-xxxxxxxx"
  }
}

variable "aws_security_group" {
  default = {
    "us-east-1" = "sg-xxxxxxxx"
    "us-west-2" = "sg-xxxxxxxx"
    "eu-west-2" = "sg-xxxxxxxx"
  }
}

### Stack Name to be associated with all resources ###
variable "stack_name" {
  default = "uiRobotStack"
}

## Server Names ##
variable "app_name" {
  default = "UiPath_Robot"
}

## Server Instances ##
variable "instance_count" {
  default = 1
}

##### Script Related Resources #####

## Set Initial Windows Administrator Password ##
variable "admin_password" {
  description = "Windows Administrator password to login as."
  default     = "winP4s5word@!4*"
}



########  RDS DB #########

variable "db_username" {
  description = "RDS master user name"
  default     = "RDS_master_username"
}

variable "db_password" {
  description = "RDS master password"
  default     = "RDS_master_password"
}

variable "db_name" {
  description = "RDS database name"
  default     = "RDS_DB_NAME"
}

// Environment name, used as prefix to name resources.
variable "environment" {
  default = "ENV_Prefix"
}

// The allocated storage in gigabytes.
variable "rds_allocated_storage" {
  default = "100"
}

// The instance type of the RDS instance.
variable "rds_instance_class" {
  default = "db.m4.large"
}

// Specifies if the RDS instance is multi-AZ.
variable "rds_multi_az" {
  default = "false"
}

// Determines whether a final DB snapshot is created before the DB instance is deleted.
variable "skip_final_snapshot" {
  type    = "string"
  default = "true"
}



//  Examples:
//  1. Get the second az in singapore:
//      "${element(var.aws_availability_zones['ap-southeast-1'], 0)}"

//  Availability zones for each region
variable "aws_availability_zones" {
  default = {
    //  N. Virginia
    us-east-1 = [
      "eu-east-1a",
      "eu-east-1b",
      "eu-east-1c",
      "eu-east-1d",
      "eu-east-1e",
      "eu-east-1f"
    ]
    //  Ohio
    us-east-2 = [
      "eu-east-2a",
      "eu-east-2b",
      "eu-east-2c",
    ]
    //  N. California
    us-west-1 = [
      "us-west-1a",
      "us-west-1b",
      "us-west-1c",
    ]
    //  Oregon
    us-west-2 = [
      "us-west-2a",
      "us-west-2b",
      "us-west-2c",
    ]
    //  Mumbai
    ap-south-1 = [
      "ap-south-1a",
      "ap-south-1b",
    ]
    //  Seoul
    ap-northeast-2 = [
      "ap-northeast-2a",
      "ap-northeast-2b",
    ]
    //  Singapore
    ap-southeast-1 = [
      "ap-southeast-1a",
      "ap-southeast-1b",
      "ap-southeast-1c",
    ]
    //  Sydney
    ap-southeast-2 = [
      "ap-southeast-2a",
      "ap-southeast-2b",
      "ap-southeast-2c",
    ]
    //  Tokyo (4)
    ap-northeast-1 = [
      "ap-northeast-1a",
      "ap-northeast-1b",
      "ap-northeast-1c",
    ]
    //  Osaka-Local (1)
    //  Central
    ca-central-1 = [
      "ca-central-1a",
      "ca-central-1b",
    ]
    //  Beijing (2)
    //  Ningxia (2)

    //  Frankfurt (3)
    eu-central-1 = [
      "eu-central-1a",
      "eu-central-1b",
      "eu-central-1c",
    ]
    //  Ireland (3)
    eu-west-1 = [
      "eu-west-1a",
      "eu-west-1b",
      "eu-west-1c",
    ]
    //  London (3)
    eu-west-2 = [
      "eu-west-2a",
      "eu-west-2b",
      "eu-west-2c",
    ]
    //  Paris (3)
    eu-west-3 = [
      "eu-west-3a",
      "eu-west-3b",
      "eu-west-3c",
    ]
    //  São Paulo (3)
    sa-east-1 = [
      "sa-east-1a",
      "sa-east-1b",
      "sa-east-1c",
    ]
    //  AWS GovCloud (US-West) (2)
  }
}


## UiPath Variables ##

variable "orchestrator_password" {
  description = "Orchestrator Administrator password to login as."
  default     = "winP4s5word@!4*"
}

#orchestrator admin password
variable "orchestrator_version" {
  default = "19.4.3"
}
