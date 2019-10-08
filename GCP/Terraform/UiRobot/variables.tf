
variable "region" {
  description = "Region"
  default = "us-west1"
}

## VM Variables ##
variable "az" {
  description = "Availability Zone"
  default = "us-west1-a"
}

variable "image" {
  default = "windows-server-2016-dc-v20190620"
}

variable "vm_type" {
  default = "n1-standard-4"
}

variable "instance_count" {
  default = 2
}

variable "disk_size" {
  default = 50
}

variable "app_name" {
  default = "uirobot"
}

### Local VM vars ###
## Set Initial Windows Administrator Password ##
variable "set_local_adminpass" {
  description = "Set local admin password."
  default = "yes"
}

variable "admin_password" {
  description = "Local windows administrator password. If variable 'set_local_adminpass' is 'yes'."
  default     = "Local@dminP@55!*"
}
## Set Robot local account role : localadmin or localuser
variable "robot_local_account_role" {
  description = "Robot local accout role : localadmin or localuser"
  default = "localadmin" 
}



## UiPath Variables ##

#orchestrator url
variable "orchestrator_url" {
  default = "https://corp-orchestrator.com"
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
  default = "Orc@dminP@55!*"
}

#Robot VM username
variable "vm_username" {
  default = "uirobot"
}

#Robot VM password
variable "vm_password" {
  default = "UiRobot@dminP@55!"
}

#Robot type
variable "robot_type" {
  # "Unattended",
  # "Attended",
  # "Nonproduction",
  # "Development"
  default = "Unattended"
}