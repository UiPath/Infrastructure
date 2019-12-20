### INLINE - Bootstrap Windows Server 2016 ###
data "template_file" "init" {
  depends_on = ["aws_elasticache_replication_group.redis-uipath", "aws_db_instance.default_mssql[0]"]
  template   = <<EOF
    <script>
      winrm quickconfig -q & winrm set winrm/config/winrs @{MaxMemoryPerShellMB="300"} & winrm set winrm/config @{MaxTimeoutms="1800000"} & winrm set winrm/config/service @{AllowUnencrypted="true"} & winrm set winrm/config/service/auth @{Basic="true"} & winrm/config @{MaxEnvelopeSizekb="8000kb"}
    </script>
    <powershell>
    netsh advfirewall firewall add rule name="WinRM in" protocol=TCP dir=in profile=any localport=5985 remoteip=any localip=any action=allow
    ### remove this if you don't want to setup a password for local admin account ###
    $admin = [ADSI]("WinNT://./administrator, user")
    $admin.SetPassword("${var.admin_password}")
    ### end of remove this if you don't want to setup a password for local admin account ###

    $temp = "C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts"
    $link = "https://raw.githubusercontent.com/UiPath/Infrastructure/master/Setup/Install-UiPathOrchestrator.ps1"
    $file = "Install-UiPathOrchestrator.ps1"
    New-Item $temp -ItemType directory
    Set-Location -Path $temp
    Set-ExecutionPolicy Unrestricted -force
    Invoke-WebRequest -Uri $link -OutFile $file
    powershell.exe -ExecutionPolicy Bypass -File "C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts\Install-UiPathOrchestrator.ps1" -OrchestratorVersion "${var.orchestrator_versions}" -passphrase "${var.orchestrator_passphrase}" -databaseServerName  "${var.newSQL == "yes" ? "${aws_db_instance.default_mssql[0].address}" : "${var.sql_srv}"}"  -databaseName "${var.db_name}"  -databaseUserName "${var.db_username}" -databaseUserPassword "${var.db_password}" -orchestratorAdminPassword "${var.orchestrator_password}" -redisServerHost "${join(":", list(aws_elasticache_replication_group.redis-uipath.primary_endpoint_address, aws_elasticache_replication_group.redis-uipath.port))}" -NuGetStoragePath "${join("\\", list(aws_instance.gateway.private_ip, var.s3BucketName))}" -orchestratorLicenseCode "${var.orchestrator_license}"
    </powershell>
EOF
}

### Bastion HOST userdata ####
data "template_file" "bastion" {
  template   = <<EOF
    <script>
      winrm quickconfig -q & winrm set winrm/config/winrs @{MaxMemoryPerShellMB="300"} & winrm set winrm/config @{MaxTimeoutms="1800000"} & winrm set winrm/config/service @{AllowUnencrypted="true"} & winrm set winrm/config/service/auth @{Basic="true"} & winrm/config @{MaxEnvelopeSizekb="8000kb"}
    </script>
    <powershell>
    netsh advfirewall firewall add rule name="WinRM in" protocol=TCP dir=in profile=any localport=5985 remoteip=any localip=any action=allow
    ### remove this if you don't want to setup a password for local admin account ###
    $admin = [ADSI]("WinNT://./administrator, user")
    $admin.SetPassword("${var.admin_password}")
    ### end of remove this if you don't want to setup a password for local admin account ###
    </powershell>
EOF
}


##############################################################
# Data sources to get AWS AMI ids
##############################################################
data "aws_ami" "server_ami" {
  most_recent = true
  owners = ["amazon", "self"]

  filter {
    name = "name"
    values = ["Windows_Server-2016-English-Full-Base-*"]
  }
}

data "aws_ami" "gateway_ami" {
  most_recent = true
  owners = ["amazon", "aws-marketplace"]

  filter {
    name = "name"
    values = ["aws-thinstaller-1528922603"]
  }
}

##############################################################
# Data sources to get VPC, subnets and security group details
##############################################################
data "aws_vpc" "uipath" {
  depends_on = ["aws_vpc.uipath"]
  #default = true
  #state = "available"
  id = "${aws_vpc.uipath.id}"
}

data "aws_subnet_ids" "public" {
  depends_on = ["aws_vpc.uipath", "aws_subnet.public"]
  vpc_id = "${aws_vpc.uipath.id}"
  tags = {
    Tier = "Public"
  }
}

data "aws_subnet_ids" "private" {
  depends_on = ["aws_vpc.uipath", "aws_subnet.private"]
  vpc_id = "${aws_vpc.uipath.id}"
  tags = {
    Tier = "Private"
  }
}


# data "aws_security_group" "uipathstack" {
#   vpc_id = "${aws_vpc.uipath.id}"
#   tags = {
#     Tier = "UiPathStack"
#   }
# }


# Declare the data source
data "aws_availability_zones" "available" {}