# Provider vars. Please check : https://docs.cloud.oracle.com/iaas/Content/API/Concepts/apisigningkey.htm 
variable "tenancy_ocid" {
  description = "OCI Tenancy ID"
  default     = "ocid1.tenancy.oc1..sag43gsdgvsddsvxcbn-demo"
}
variable "user_ocid" {
  description = "OCI User ID"
  default     = "ocid1.user.oc1..sag43gsdgvsddsvxcbn-demo"
}
variable "fingerprint" {
  description = "Key fingerprint from OCI"
  default     = "aa:44:55:66:78:gg:nn:aa:hh:ss:-demo"
}
variable "private_key_path" {
  # Please use full path of the public pem key.
  description = "Public key path"
  default     = "key\\oci_key.pem"
}
variable "region" {
  # Chose your region. Please check : https://docs.cloud.oracle.com/iaas/Content/General/Concepts/regions.htm
  description = "Region"
  default     = "uk-london-1"
}
variable "compartment_ocid" {
  description = "OCI Compartment ID"
  default     = "ocid1.tenancy.oc1..sasfffaaadgvsddsvxcbn-demo"
}

# Compute vars.
variable instance_image_ocid {
  description = "OCI Image ID"
  type        = "map"

  default = {
    # Image OCIDs for Windows-Server-2016-Standard-Edition-VM-Gen2-2019.08.15-0
    # Please use following link to map the image for other regions : https://docs.cloud.oracle.com/iaas/images/image/4695d197-1e1a-4c71-b891-df3952b94288/

    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaazlvwdcp5ujhsfrogqfdjtupsikqe252rqx6j2bd3zxbmsgufcleq"
    us-ashburn-1   = "ocid1.image.oc1.iad.aaaaaaaa47jc54umovg4mwykxwmq737tbux37gr6klobblgy7lbrir5lhkma"
    uk-london-1    = "ocid1.image.oc1.uk-london-1.aaaaaaaadw3ofwcwpfkzd7wpsrovn2h4dyfxorrtcld35hhhgbw4uyg5aahq"
    us-phoenix-1   = "ocid1.image.oc1.phx.aaaaaaaaadolnlphtmhqa25pqpkexljfca7p2skobxjlwsw55buhwj5okfyq"

  }
}
# Compute vars
variable "instance_shape" {
  # Please check : https://docs.cloud.oracle.com/iaas/Content/Compute/References/computeshapes.htm
  description = "Instance tier"
  default     = "VM.Standard2.2"
}

variable "size_in_gbs" {
  # Instance disk size. Minimum 256
  description = "VM disk size"
  default     = "256"
}

variable "instance_name" {
  description = "VM prefix name"
  default     = "UiRobot"
}
variable "instance_count" {
  description = "Robots count"
  default     = 2
}
variable "instance_username" {
  description = "Default username for OCI is opc"
  default     = "opc"

}
variable "instance_password" {
  description = "Password for local username"
  default     = "P@s5w0r4!"
}

## Set Robot local account role : localadmin or localuser
variable "robot_local_account_role" {
  description = "Robot local accout role : localadmin or localuser"
  default     = "localadmin"
}

# UiPath vars

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


#Robot type
variable "robot_type" {
  # "Unattended",
  # "Attended",
  # "Nonproduction",
  # "Development"
  default = "Unattended"
}
variable "addRobotToExistingEnvs" {
  description = "Add Robot to all existing environments"
  default     = "No" #Yes
}

# Networking vars
variable "vcn_cidr" {
  description = "VCN CIDR"
  default     = "10.1.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  default     = "10.1.20.0/24"
}
variable "vcn_dns_label" {
  description = "DNS label for VCN"
  default     = "uiprovcn"

}
variable "subnet_dns_label" {
  description = "DNS label for subnet"
  default     = "uiprosubnet"
}


variable "prefix_label" {
  description = "Label prefix for provisioned resources"
  default     = "UiRobot"

}
