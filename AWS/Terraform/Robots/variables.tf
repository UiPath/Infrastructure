## Provider Variables ##
variable "aws_region" {
  description = "AWS region for deployment."
  default     = "eu-west-2"
}

variable "access_key" {
  description = "AWS access key."
  default = ""
}

variable "secret_key" {
  description = "AWS secret key."
  default = ""
}

variable "key_name" {
  description = "SSH keypair to be used."
  default = {
    "us-east-1" = "SSH_KeyPair"
    "eu-west-2" = "SSH_KeyPair"
  }
}

##### Robots Instance Type, Count and Size ####
variable "aws_app_instance_type" {
  description = "Robot EC2 Instance type." 
  default = "t2.medium"
}

variable "disk_size" {
  description = "Local disk size."
  default = 100
}

variable "instance_count" {
  description = "Number of the Robots to be created."
  default = 2
}
#### Stack prefix name ####
variable "application" {
  description = "Robots and stack prefix name." 
  default = "uirobot"
}

variable "environment" {
  description = "Environment type, also used as a prefix for the stack."
  default = "prod"
}

##### Local OS Related Resources #####

## Set Initial Windows Administrator Password ##
variable "set_local_adminpass" {
  description = "Set local admin password."
  default = "yes"
}

variable "admin_password" {
  description = "Local windows administrator password. If variable 'set_local_adminpass' is 'yes'."
  default     = "Local@dminP@55!*"
}

###### networking.tf vars ######
##### VPC #####
variable "cidr_block" {
  type        = "string"
  description = "VPC cidr block."
  default     = "10.0.0.0/16"
}

##### Public IP association #####
variable "associate_public_ip_address" {
  description = "Associate public IP to Robots EC2 instances."
  default = "false"  
}


######  Security CIDR block #####
variable "security_cidr_block" {
  type        = "string"
  description = "Security Group cidr block."
  default     = "0.0.0.0/0"
}


############
#  Examples:
#  1. Get the second AZ in Singapore:
#     "${element(var.aws_availability_zones['ap-southeast-1'], 0)}"
#  Availability zones for each region
variable "aws_availability_zones" {
  description = "Availability zones for each region. Example to get the second AZ in Singapore : 'element(var.aws_availability_zones['ap-southeast-1'], 0)' " 
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


##########  Locals ##########
locals {
  description = "Used to get all AZ from the region."
  aws_region = "${var.aws_availability_zones["eu-west-2"]}"
}

##### Orchestrator parameters ####
variable "orchestrator_url" {
  description = "URL of an existing and licensed Orchestrator."
  default = "https://my-licensed-orchestrator.net"
}

variable "tenant" {
  description = "Orchestrator Tenant."
  default = "default"  
}

variable "robot_type" {
  description = "Robot type : Attended, Unattended, Development or Nonproduction."
  default = "Unattended"
}

variable "api_user" {
  description = "API user with View, Edit, Create, Delete roles for Machines,Robots and Environments."
  default = "apiUser"
}

variable "api_user_password" {
  description = "API user password."
  default = "ApiP@ssWd"
}

variable "robot_local_account" {
  description = "Robot local account which will be created. Don't use 'administrator'."
  default = "robolocal"
}

variable "robot_local_account_password" {
  description = "Robot local account password."
  default = "R@pVPsf@Fx" 
}

variable "robot_local_account_role" {
  description = "Robot local accout role : localadmin or localuser"
  default = "localadmin" 
}


