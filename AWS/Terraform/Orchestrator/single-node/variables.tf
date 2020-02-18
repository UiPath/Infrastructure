## Provider Variables ##
### AWS Region ###
variable "aws_region" {
  description = "The region for UiPath Orchestrator deployment."
  default     = "eu-west-2"
}
### AWS Access Key ###
variable "access_key" {
  description = "AWS Access Key."
  default     = "SAGFGDGVGDBXCVER"
}
### AWS Secret Access Key ###
variable "secret_key" {
  description = "AWS Secret Access Key."
  default     = "+SAGFGDGVGDBXCVERSAGFGDGVGDBXCVER=="
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
  default     = "m4.large"
}

## Environment name, used as prefix to name resources.
variable "environment" {
  description = "Environment name, used as prefix to tag the name of the resources."
  default     = "dev"
}
## Application name, used as prefix to name resources.
variable "application" {
  description = "Application stack name, used as prefix to tag the name of the resources."
  default     = "OrchestratorStack"
}

##### Script Related Resources #####

########  RDS DB #########

# Database username
variable "db_username" {
  description = "RDS master user name."
  default     = "devawsdb"
}

# Database username password, avoid using '/', '\"', or '@' 
variable "db_password" {
  description = "RDS Master password."
  default     = "!vfdgva%gsd"
}

# Database name
variable "db_name" {
  description = "RDS database name."
  default     = "awstest"
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
      "eu-east-1f",
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
  }
  //  Beijing (2)
  //  Ningxia (2)

  //  AWS GovCloud (US-West) (2)
}

## UiPath Variables ##

#orchestrator admin password
variable "orchestrator_password" {
  description = "Orchestrator Administrator password to login in Default and Host Tennant."
  default     = "0rCh35Tr@tor!"
}

variable "orchestrator_version" {
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

## Set Initial Windows Administrator Password ##
variable "admin_password" {
  description = "Windows Administrator password used to login in the provisioned VMs."
  default     = "WinP@55!"
}

variable "orchestrator_passphrase" {
  description = "Orchestrator Passphrase used to generate NuGet API keys, App encryption key and machine keys."
  default = "!asfgre2%gsd"
}

variable "orchestrator_license" {
  description = "Orchestrator license code. The license created with regutil."
  default     = "TheLicenseCreatedwithRegUtil"
}