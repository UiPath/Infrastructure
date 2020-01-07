### template file ###
### INLINE - Bootstrap Windows Server 2016 ###
data "template_file" "init" {
  template = <<EOF
    if(![System.IO.File]::Exists("C:\Program Files\Google\Compute Engine\metadata_scripts\createRobotUser")){

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

    $UserName="${var.vm_username}"
    $Password="${var.vm_password}"
    $Computer = [ADSI]"WinNT://$Env:COMPUTERNAME,Computer"
    $User = $Computer.Create("User", $UserName)
    $User.SetPassword("$Password")
    $User.SetInfo()
    $User.FullName = "${var.vm_username}"
    $User.SetInfo()
    $User.Put("Description", "UiPath Robot Admin Account")
    $User.SetInfo()
    $User.UserFlags = 65536
    $User.SetInfo()
    $Group = [ADSI]("WinNT://$Env:COMPUTERNAME/$localRobotRole,Group")
    $Group.add("WinNT://$Env:COMPUTERNAME/$UserName")
    $admin = [ADSI]("WinNT://./administrator, user")
    $admin.SetPassword("${var.vm_password}")
    New-Item "C:\Program Files\Google\Compute Engine\metadata_scripts\createRobotUser" -type file
    }

    if(![System.IO.File]::Exists("C:\Program Files\Google\Compute Engine\metadata_scripts\installRobot")){
    Set-ExecutionPolicy Unrestricted -force 
    Invoke-WebRequest https://raw.githubusercontent.com/hteo1337/UiRobot/master/Setup/Install-UiRobot.ps1 -OutFile "C:\Program Files\Google\Compute Engine\metadata_scripts\Install-UiRobot.ps1"
    powershell.exe -ExecutionPolicy Bypass -File "C:\Program Files\Google\Compute Engine\metadata_scripts\Install-UiRobot.ps1"  -orchestratorUrl "${var.orchestrator_url}" -Tennant "${var.orchestrator_tennant}" -orchAdmin "${var.orchestrator_admin}" -orchPassword "${var.orchestrator_adminpw}" -adminUsername "${var.vm_username}" -machinePassword "${var.vm_password}" -RobotType "${var.robot_type}"
    New-Item "C:\Program Files\Google\Compute Engine\metadata_scripts\installRobot" -type file
    Remove-Item -Path  "C:\Program Files\Google\Compute Engine\metadata_scripts\Install-UiRobot.ps1" -Force
    #Start-Sleep -Seconds 10 ; Restart-Computer -Force
    }
EOF
}


### Delete default metadata after VM provisioning
resource "google_compute_project_metadata" "default"  {
    depends_on = ["google_compute_instance.uipath"]
    metadata = {
    windows-startup-script-ps1  = "null"
    }
}
