### INLINE - Bootstrap Windows Server 2016 ###
data "template_file" "init" {
  depends_on = ["aws_instance.haa-master", "aws_db_instance.default_mssql[0]"]
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
powershell.exe -ExecutionPolicy Bypass -File "C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts\Install-UiPathOrchestrator.ps1" -OrchestratorVersion "${var.orchestrator_versions}" -passphrase "${var.orchestrator_passphrase}" -databaseServerName  "${var.newSQL == "yes" ? "${aws_db_instance.default_mssql[0].address}" : "${var.sql_srv}"}"  -databaseName "${var.db_name}"  -databaseUserName "${var.db_username}" -databaseUserPassword "${var.db_password}" -orchestratorAdminPassword "${var.orchestrator_password}" -redisServerHost "${aws_instance.haa-master.private_ip}:10000,password=${var.haa-password}" -NuGetStoragePath "${join("\\", list(aws_instance.gateway.private_ip, var.s3BucketName))}" -orchestratorLicenseCode "${var.orchestrator_license}"
</powershell>
EOF
}

### HAA ####
data "template_file" "haa-master" {
  template   = <<EOF
#!/bin/bash
yum update -y
yum install -y wget
wget http://download.uipath.com/haa/get-haa.sh
chmod +x get-haa.sh
sh get-haa.sh -u ${var.haa-user} -p ${var.haa-password} -l ${var.haa-license}
EOF
}

data "template_file" "haa-slave" {
  template   = <<EOF
#!/bin/bash
yum update -y
yum install -y wget
wget http://download.uipath.com/haa/get-haa.sh
chmod +x get-haa.sh
sh get-haa.sh -u  ${var.haa-user} -p ${var.haa-password} -j ${aws_instance.haa-master.private_ip}
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
    values = ["Windows_Server-2019-English-Full-Base-*"]
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
data "aws_ami" "haa" {
  most_recent = true
  owners = ["amazon", "aws-marketplace", "309956199498" ] #Amazon Web Services ID

  name_regex = "^RHEL-7.*x86_64.*"

  # filter {
  #   name = "name"
  #   values = ["^RHEL-7.*x86_64.*"]#["RHEL-7*"] 
  # }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
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

# Declare the data source
data "aws_availability_zones" "available" {}