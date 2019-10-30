### Variables #######
## check this link for sizing https://docs.uipath.com/orchestrator/docs/hardware-requirements-orchestrator#section-support-between-250-and-500-unattended-robots

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


###



###

variable  "win_image" {
  #  default = "666078e1-a0fe-48c6-953e-098008c4c722"
    default = "d34455d4-c48d-42f2-b9d4-dcbc73e2aa11"

}

variable "win_flavor" {
    default = "s3.2xlarge.2"
}

variable "orchestrator_count" {
     default = 2
}

variable "default_sec_group" {
    default = "b13576ed-560b-4c77-a733-b22627f243cc"
## Manually created from webui -- ATM - needs to be dynamically collected

}

##### Script Related Resources #####


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

variable "elasticache" {
  description = "Tag name of the ElastiCache - Redis."
  default = "UiPath-Redis"
}

variable "redis_password" {
  description = "Used to create redis instance"
  default     = "CatsiCumreayu8"
}
########  RDS DB #########

# Database username
variable "db_username" {
  description = "RDS master user name or username of the existing database."
  default     = "rdsuser"   ### HARDCODED BY FE BUG
 }

# Database username password, avoid using '/', '\"', or '@'
variable "db_password" {
  # description = "Existing Database username password or create a password for the RDS. RDS Master Password must be at least eight characters long, as in \'mypassword'. Can be any printable ASCII character except '/', '\"', or '@'. "
  default     =  "Oareceparolaw0rd"
}

# Database name
variable "db_name" {
  description = "RDS database name or the name of an existing database."
  default     = "uiptahdb"
}


variable "mssql_storage_type" {
       default = "ULTRAHIGH"  ## SSD or COMMON for SATA
 }


 variable "mssql_engine" {
     default ="2014_EE"
 }

# The allocated storage in gigabytes.
variable "rds_allocated_storage" {
  description = "Allocated storage (in GB) for the RDS instance."
  default = "600"
}

# The instance size type of the RDS instance.
variable "rds_instance_class" {
  description = "Instance size type of the RDS instance."
  default = "rds.mssql.c2.4xlarge.ha"
##  default = "rds.mssql.s1.4xlarge.ha"  # 16 vCPUs 64 GB
## can be also rds.mssql.c2.4xlarge.ha | 16 vCPUs | 32 GB
}
