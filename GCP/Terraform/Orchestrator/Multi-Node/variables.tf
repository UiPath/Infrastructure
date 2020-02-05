variable "project" {
  description = "GCP project name"
}

variable "region" {
  description = "Region"
  default     = "us-east1"
}

## VM Variables ##
variable "az" {
  description = "Availability Zone"
  default     = "us-east1-b"
}

variable "image" {
  default = "windows-server-2016-dc-v20190620"
}

variable "vm_type" {
  default = "n1-standard-4"
}

variable "instance_count" {
  default = 1
}

variable "disk_size" {
  default = 50
}

variable "app_name" {
  default = "orchestrator"
}

### Local VM vars ###
## Set Initial Windows Administrator Password ##
variable "set_local_adminpass" {
  description = "Set local admin password."
  default     = "yes"
}

variable "admin_password" {
  description = "Local windows administrator password. If variable 'set_local_adminpass' is 'yes'."
  default     = "Password12"
}
## Set Orchestrator local account role : localadmin or localuser
variable "orchestrator_local_account_role" {
  description = "Orchestrator local accout role : localadmin or localuser"
  default     = "localadmin"
}

#Orchestrator VM username
variable "vm_username" {
  default = "uioadmin"
}

#Orchestrator VM password
variable "vm_password" {
  default = "Password12"
}
## UiPath Variables ##

#orchestrator version
variable "orchestrator_version" {
  default = "19.4.4"
}

#orchestrator passphrase
variable "orchestrator_passphrase" {
  default = "Password12"
}

#orchestrator databaseServerName
variable "orchestrator_databaseservername" {
  default = "sqlhost"
}

#orchestrator databaseName
variable "orchestrator_databasename" {
  default = "uipath"
}

#orchestrator databaseuserName
variable "orchestrator_databaseusername" {
  default = "sa"
}

#orchestrator databaseUserPassword
variable "orchestrator_databaseuserpassword" {
  default = "Password12"
}

#orchestrator orchestratoradminpassword
variable "orchestrator_orchestratoradminpassword" {
  default = "Password12"
}

variable "create_redis" {
  description = "Create managed Redis instance?"
  default     = "true"
}

variable "redis_host" {
  description = "Redis instance name or address"
}

variable "redis_port" {
  default = "6379"
}

variable "redis_capacity" {
  description = "Redis instance size in GBs"
  default     = "4"
}

variable "max_instances" {
  description = "Max number of Orchestratot instances in a group"
  default     = "3"
}

variable "orchestrator_domain" {
  description = "Domain name to be used for orchestrator's load balancer"
}

variable "create_sql" {
  description = "Create managed SQLServer instance?"
  default     = "false"
}

variable "sql_root_pass" {
  description = "Root password for SQLServer; Required to create instance"
}
