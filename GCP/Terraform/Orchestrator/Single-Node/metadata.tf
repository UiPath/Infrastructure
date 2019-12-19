### template file ###
### INLINE - Bootstrap Windows Server 2016 ###
data "template_file" "init" {
  template = <<EOF
    if(![System.IO.File]::Exists("C:\Program Files\Google\Compute Engine\metadata_scripts\createorchestratorUser")){

    $setLocalAdminPassword = "${var.set_local_adminpass}"
    if($setLocalAdminPassword -eq "yes") {
    $admin = [ADSI]("WinNT://./administrator, user")
    $admin.SetPassword("${var.admin_password}")
    }

    # create orchestrator local user 
    $orchestratorRole = "${var.orchestrator_local_account_role}"
    if($orchestratorRole -eq "localuser") {
     $localorchestratorRole = "Remote Desktop Users"
    } else { $localorchestratorRole = "Administrators" }

    $UserName="${var.vm_username}"
    $Password="${var.vm_password}"
    $Computer = [ADSI]"WinNT://$Env:COMPUTERNAME,Computer"
    $User = $Computer.Create("User", $UserName)
    $User.SetPassword("$Password")
    $User.SetInfo()
    $User.FullName = "${var.vm_username}"
    $User.SetInfo()
    $User.Put("Description", "UiPath orchestrator Admin Account")
    $User.SetInfo()
    $User.UserFlags = 65536
    $User.SetInfo()
    $Group = [ADSI]("WinNT://$Env:COMPUTERNAME/$localorchestratorRole,Group")
    $Group.add("WinNT://$Env:COMPUTERNAME/$UserName")
    $admin = [ADSI]("WinNT://./administrator, user")
    $admin.SetPassword("${var.vm_password}")
    New-Item "C:\Program Files\Google\Compute Engine\metadata_scripts\createorchestratorUser" -type file
    }

    if(![System.IO.File]::Exists("C:\Program Files\Google\Compute Engine\metadata_scripts\orchinstall")){
    Set-ExecutionPolicy Unrestricted -force
    Invoke-WebRequest https://raw.githubusercontent.com/UiPath/Infrastructure/master/Setup/Install-UiPathOrchestrator.ps1 -OutFile "C:\Program Files\Google\Compute Engine\metadata_scripts\Install-UiPathOrchestrator.ps1"
    powershell.exe -ExecutionPolicy Bypass -File "C:\Program Files\Google\Compute Engine\metadata_scripts\Install-UiPathOrchestrator.ps1" -orchestratorversion "${var.orchestrator_version}" -passphrase "${var.orchestrator_passphrase}" -databaseservername "${var.orchestrator_databaseservername}" -databasename "${var.orchestrator_databasename}" -databaseusername "${var.orchestrator_databaseusername}" -databaseuserpassword "${var.orchestrator_databaseuserpassword}" -orchestratoradminpassword "${var.orchestrator_orchestratoradminpassword}"
    New-Item "C:\Program Files\Google\Compute Engine\metadata_scripts\orchinstall" -type file
    #Start-Sleep -Seconds 10 ; Restart-Computer -Force
    }
EOF
}


### Delete default metadata after VM provisioning
resource "google_compute_project_metadata" "default" {
  depends_on = ["google_compute_instance.uipath"]
  metadata = {
    windows-startup-script-ps1 = "null"
  }
}