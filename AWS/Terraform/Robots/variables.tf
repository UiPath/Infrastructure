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
  default = "t2.medium"
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

## UiPath Variables ##

#orchestrator url
variable "orchestrator_url" {
  default = "https://orchestrator-url"
}

#orchestrator tennant
variable "orchestrator_tennant" {
  default = "default"
}

#orchestrator admin username
variable "orchestrator_admin" {
  default = "admin"
}

#orchestrator admin password
variable "orchestrator_adminpw" {
  default = "adminpassword"
}

#Robot VM username
variable "vm_username" {
  default = "vm_username"
}

#Robot VM password
variable "vm_password" {
  default = "vm_password"
}

#Robot Hosting Type
variable "hosting_type" {
  default = "Standard"
}

#Robot type
variable "robot_type" {
  # "Unattended",
  # "Attended",
  # "Nonproduction",
  # "Development"

  default = "Unattended"

}

#Robot credentials type
variable "cred_type" {
  default = "Default"
}
