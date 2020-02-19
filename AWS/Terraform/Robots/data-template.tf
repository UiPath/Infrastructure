### INLINE - Bootstrap Windows Server 2016 ###
data "template_file" "init" {
  count         = "${var.instance_count}"
  template = <<EOF
    <script>
      winrm quickconfig -q & winrm set winrm/config/winrs @{MaxMemoryPerShellMB="300"} & winrm set winrm/config @{MaxTimeoutms="1800000"} & winrm set winrm/config/service @{AllowUnencrypted="true"} & winrm set winrm/config/service/auth @{Basic="true"} & winrm/config @{MaxEnvelopeSizekb="8000kb"}
    </script>
    <powershell>
    netsh advfirewall firewall add rule name="WinRM in" protocol=TCP dir=in profile=any localport=5985 remoteip=any localip=any action=allow

    $setLocalAdminPassword = "${var.set_local_adminpass}"
    if($setLocalAdminPassword -eq "yes") {
    $admin = [ADSI]("WinNT://./administrator, user")
    $admin.SetPassword("${var.admin_password}")
    }

    # create Robot local user 
    $robotRole = "${var.robot_local_account_role}"
    if($robotRole -eq "localuser") {
      $localRobotRole = "Remote Desktop Users"
    } else { $localRobotRole = "Administrators" }

    $UserName="${var.robot_local_account}"
    $Password="${var.robot_local_account_password}"
    
    $Computer = [ADSI]"WinNT://$Env:COMPUTERNAME,Computer"
    $User = $Computer.Create("User", $UserName)
    $User.SetPassword("$Password")
    $User.SetInfo()
    $User.FullName = "${var.robot_local_account}"
    $User.SetInfo()
    $User.Put("Description", "UiPath Robot Account")
    $User.SetInfo()
    $User.UserFlags = 65536
    $User.SetInfo()
    $Group = [ADSI]("WinNT://$Env:COMPUTERNAME/$localRobotRole,Group")
    $Group.add("WinNT://$Env:COMPUTERNAME/$UserName")
    # end create Robot local user

    $newMachineName = "${var.application}-${var.environment}-${count.index}"
    Rename-Computer -NewName $newMachineName -Force 

    $temp = "C:\scripts"
    $link = "https://raw.githubusercontent.com/UiPath/Infrastructure/master/Setup/Install-UiRobot.ps1"
    $file = "Install-UiRobot.ps1"
    New-Item $temp -ItemType directory
    Set-Location -Path $temp
    Set-ExecutionPolicy Unrestricted -force
    Invoke-WebRequest -Uri $link -OutFile $file
    & "C:\scripts\Install-UiRobot.ps1" -orchestratorUrl "${var.orchestrator_url}" -Tennant "${var.tenant}" -orchAdmin "${var.api_user}" -orchPassword "${var.api_user_password}" -adminUsername "${var.robot_local_account}" -machinePassword "${var.robot_local_account_password}" -machineName "$newMachineName" -HostingType "Standard" -RobotType "${var.robot_type}" -credType "Default"
    Remove-Item -LiteralPath "C:\scripts" -Force -Recurse
    shutdown /r /f /t 5 /c "forced reboot"
    </powershell>
EOF
}

data "aws_ami" "server_ami" {
  most_recent = true
  owners = ["amazon", "self"]

  filter {
    name = "name"
    values = ["Windows_Server-2016-English-Full-Base-*"]
  }
}

### Bastion HOST userdata ####
data "template_file" "bastion" {
  template   = <<EOF
    <script>
      winrm quickconfig -q & winrm set winrm/config/winrs @{MaxMemoryPerShellMB="300"} & winrm set winrm/config @{MaxTimeoutms="1800000"} & winrm set winrm/config/service @{AllowUnencrypted="true"} & winrm set winrm/config/service/auth @{Basic="true"} & winrm/config @{MaxEnvelopeSizekb="8000kb"}
    </script>
    <powershell>
    netsh advfirewall firewall add rule name="WinRM in" protocol=TCP dir=in profile=any localport=5985 remoteip=any localip=any action=allow
    $setLocalAdminPassword = "${var.set_local_adminpass}"
    if($setLocalAdminPassword -eq "yes") {
    $admin = [ADSI]("WinNT://./administrator, user")
    $admin.SetPassword("${var.admin_password}")
    }
    </powershell>
EOF
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