##"flexibleengine_dns_recordset_v2.cds_uipath_local" --FE BUG not returning IP -- need to wiat meanwhile collect manully from interface after first time failure
data "template_file" "init" {
  # depends_on = ["flexibleengine_rds_instance_v3.uipathdb","flexibleengine_dns_recordset_v2.cds_uipath_local"]
depends_on = ["flexibleengine_rds_instance_v3.uipathdb"]
  template   = <<EOF
<script>
winrm quickconfig -q & winrm set winrm/config/winrs @{MaxMemoryPerShellMB="300"} & winrm set winrm/config @{MaxTimeoutms="1800000"} & winrm set winrm/config/service @{AllowUnencrypted="true"} & winrm set winrm/config/service/auth @{Basic="true"} & winrm/config @{MaxEnvelopeSizekb="8000kb"}
<script>
<powershell>
netsh advfirewall firewall add rule name="WinRM in" protocol=TCP dir=in profile=any localport=5985 remoteip=any localip=any action=allow
### remove this if you don't want to setup a password for local admin account ###
$admin = [ADSI]("WinNT://./administrator, user")
$admin.SetPassword("${var.admin_password}")
### end of remove this if you don't want to setup a password for local admin account ###
$temp = "C:\Temp"
$link = "https://raw.githubusercontent.com/Mihai-CMM/Infrastructure/main/Setup/Install-UiPathOrchestrator.ps1"
$file = "Install-UiPathOrchestrator.ps1"
New-Item $temp -ItemType directory
New-Item -Path "C:\Temp" -Name "log" -ItemType "directory"
Set-Location -Path $temp
Set-ExecutionPolicy Unrestricted -force
Invoke-WebRequest -Uri $link -OutFile $file
powershell.exe -ExecutionPolicy Unrestricted -File "C:\Temp\Install-UiPathOrchestrator.ps1" -OrchestratorVersion "${var.orchestrator_versions}" -passphrase "${var.orchestrator_passphrase}" -databaseServerName  "mssql.uipath.local"  -databaseName "${var.db_name}"  -databaseUserName "${var.db_username}" -databaseUserPassword "${var.db_password}" -orchestratorAdminPassword "${var.orchestrator_password}" -redisServerHost "redis.uipath.local:6379,password=${var.redis_password}"
</powershell>
EOF
}
