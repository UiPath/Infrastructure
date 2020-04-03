## Provider Variables ##
### All variables are collected from local machine environment after sourceing passwords.mock

##### Robots Instance Type, Count and Size ####
variable "win_flavor" {
  description = "Robot ECS Instance type."
  default = "s3.large.2"
}

variable  "win_image" {
    description = "Robot ECS Windows version - Win2016 "
    default = "d34455d4-c48d-42f2-b9d4-dcbc73e2aa11"
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

###### vpc.tf vars ######
#### Openstack router aka VPC in FE terminalogy
variable "vpc_name" {
  default = "uipath"
}

variable "vpc_cidr" {
  default = "172.19.0.0/16"
}

variable "subnet_name" {
     default = "uipath_subnet"
}

variable "subnet_cidr" {
     default = "172.19.1.0/24"
}


variable "subnet_gateway_ip" {
     default = "172.19.1.1"
}



##### Orchestrator parameters ####
variable "orchestrator_url" {
  description = "URL of an existing and licensed Orchestrator."
  default = "http://cloud.uipath.orange.ro"
}

variable "tennant" {
  description = "Orchestrator Tennant."
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


###Security
variable "default_sec_group" {
    default = "1b922846-de33-4907-a1b1-685c0e9f3259"
## Manually created from webui -- ATM - needs to be dynamically collected
}
