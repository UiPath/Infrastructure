### Variables #######
## check this link for sizing https://docs.uipath.com/orchestrator/docs/hardware-requirements-orchestrator#section-support-between-250-and-500-unattended-robots


variable "vpc_name" {
  default = "uipath_vpc"
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

variable "mssql_flavour" {
       default = "rds.mssql.c2.4xlarge.ha"
   ##  default = "rds.mssql.s1.4xlarge.ha"  # 16 vCPUs 64 GB
   ## can be also rds.mssql.c2.4xlarge.ha | 16 vCPUs | 32 GB
}


variable "mssql_engine" {
    default ="2014_EE"
}
variable "mssql_size" {
	default = 600
}

variable "mssql_storage_type" {
       default = "ULTRAHIGH"  ## SSD or COMMON for SATA
 }


###

variable  "win_image" {
  #  default = "666078e1-a0fe-48c6-953e-098008c4c722"
    default = "d34455d4-c48d-42f2-b9d4-dcbc73e2aa11"

}

variable "win_flavor" {
    default = "s3.2xlarge.2"
}
