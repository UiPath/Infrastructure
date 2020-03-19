data "template_file" "init" {
  template = <<EOF
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
    powershell.exe -ExecutionPolicy Bypass -File "C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts\Install-UiPathOrchestrator.ps1" -OrchestratorVersion "${var.orchestrator_version}" -passphrase "${var.orchestrator_passphrase}" -databaseServerName  "${aws_db_instance.default_mssql.address}"  -databaseName "${var.db_name}"  -databaseUserName "${var.db_username}" -databaseUserPassword "${var.db_password}" -orchestratorAdminPassword "${var.orchestrator_password}" -orchestratorLicenseCode "${var.orchestrator_license}"
    </powershell>
EOF

}

data "aws_ami" "server_ami" {
  most_recent = true
  owners = ["amazon", "self"]

  filter {
    name = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
}

