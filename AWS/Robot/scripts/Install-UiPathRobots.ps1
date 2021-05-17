[CmdletBinding()]
Param (
  [Parameter(Mandatory = $false)]
  [string] $orchestratorUrl,

  [Parameter(Mandatory = $false)]
  [string] $tenant,

  [Parameter(Mandatory = $false)]
  [string] $orchAdmin,

  [Parameter(Mandatory = $false)]
  [string] $orchPassword,

  [Parameter(Mandatory = $false)]
  [string] $machineAdminUsername,

  [Parameter(Mandatory = $false)]
  [string] $machinePassword,

  [Parameter(Mandatory = $false)]
  [string] $hostingType,

  [Parameter(Mandatory = $true)]
  [ValidateSet("Unattended", "Attended")]
  [string] $robotType,

  [Parameter(Mandatory = $true)]
  [string] $artifactFileName,

  [Parameter(Mandatory = $false)]
  [ValidateSet('Azure', 'AWS', 'GCP', 'Oracle')]
  [string] $cloudName,

  [Parameter()]
  [string] $credType = "Default",

  [Parameter(Mandatory = $false)]
  [switch] $doNotTrustSelfSigned

)
#region Utils Section
function Generate-RandomString {
  $str = -join ((48..57) + (97..122) | Get-Random -Count 4 | ForEach-Object { [char]$_ })
  return $str
}
#endregion

$ErrorActionPreference = "Stop"
$logFile = "Installation.log"
Start-Transcript -Path $logFile -Append -IncludeInvocationHeader
$script:workDirectory = Get-Location

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Main {

  Write-Output "Install-UiRobot starts"
  $msiPath = Join-Path $script:workDirectory $artifactFileName
  
  $folderName = "$($cloudName)Deployed"
  $machineTemplateName = "$($cloudName)Template-$($env:computername)"
  $randomString = Generate-RandomString
  $userName = "$($env:computername)-$($randomString)"
  $robotUserName = "$env:computername\$machineAdminUsername"

  if (!$doNotTrustSelfSigned) {
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
  }

  Test-UiRobotExePath

  Install-RobotWithMSI -msiPath $msiPath -robotInstallType $robotType

  $robotExePath = Get-UiRobotExePath

  if ($orchestratorUrl -and $orchAdmin -and $orchPassword -and $tenant) {  
    Write-Output "orchestratorUrl $orchestratorUrl"
    Write-Output "orchAdmin $orchAdmin"
    Write-Output "tenant $tenant"

    $websession = Get-UiPathOrchestratorLoginSession
 
    Add-UiPathRobotFolder -session $websession -folderName $folderName
    if ($cloudName -eq "AWS") {
      if ($robotType -eq "Unattended") {
        Add-LocalAdministrator -userName $userName
        Add-UiPathRobotUser -session $websession -robotUsername "$env:computername\$userName" -userName $userName 
        Write-Output "Added AWS Robot: $userName"
      }
      elseif ($robotType -eq "Attended") {
        Add-UiPathRobotUser -session $websession -robotUsername "$env:computername\Administrator" -userName $userName 
        Write-Output "Added AWS Robot: $userName"
      }
    }
    elseif ($cloudName -eq "Azure") {
      Add-UiPathRobotUser -session $websession -userName $userName -robotUsername $robotUserName 
      Write-Output "Added Azure Robot: $robotUserName"
    }

    $key = Add-UiPathMachineTemplate -session $websession -templateName $machineTemplateName

    Add-UserToFolder -session $websession -folderName $folderName -userName $userName
    Write-Output "Creating UiPath machine template..."
    Add-MachineTemplateToFolder -session $websession -folderName $folderName -templateName $machineTemplateName


    #Making sure the process is running before we connect to the orchestrator.
    Start-Process -FilePath $robotExePath -Verb runas
    Wait-Service -servicesName "UiPath Robot*"
    & $robotExePath --connect -url $orchestratorUrl -key $key
  }
  Write-Output "Install completed successfully."
}

function Get-UiPathOrchestratorLoginSession {

  $dataLogin = @{
    tenancyName            = $tenant
    usernameOrEmailAddress = $orchAdmin
    password               = $orchPassword
  } | ConvertTo-Json
  
  $orchUrlLogin = "$orchestratorUrl/api/Account/Authenticate"
  
  try {
    $orchWebResponse = Invoke-RestMethod -Uri $orchUrlLogin -Method Post -Body $dataLogin -ContentType "application/json" -UseBasicParsing -SessionVariable websession
  }
  catch {
    Write-Error "Authentication failed with message: $($_.ErrorDetails.Message)"
    Exit 1
  }
  $websession.Headers.Add('Authorization', "Bearer " + $orchWebResponse.result)

  return $websession
}

function Add-UiPathRobotFolder ($session, $folderName) {
  $orchFolders = "$orchestratorUrl/odata/Folders"
  $dataFolders = @{
    DisplayName     = $folderName
    ProvisionType   = "Automatic"
    PermissionModel = "FineGrained"
    FeedType        = "Processes"
  } | ConvertTo-Json -Depth 3
  
  $getFolders = Invoke-RestMethod -Uri "$orchFolders`?`$filter=DisplayName eq `'$folderName`'" `
    -Method GET `
    -ContentType "application/json" `
    -UseBasicParsing `
    -WebSession $session

  if ($getFolders.'@odata.count' -eq 1) {
    return
  }

  try {
    Invoke-WebRequest -Uri "$orchFolders" `
      -Method POST `
      -Body $dataFolders `
      -ContentType "application/json" `
      -UseBasicParsing `
      -WebSession $session
  }
  catch {
    if ($_.ErrorDetails.Message.Contains("already used")) {
      #The folder was already created by another machine (limited race condition)
      return
    }
    else { 
      Write-Error "Terminating error: $($_.ErrorDetails.Message)"  
      Exit 1 
    }
  }
}

function Add-LocalAdministrator($userName) {
  
  Write-Output "Creating admin user for the robot to connect with."
  $userPassword = ConvertTo-SecureString $machinePassword -AsPlainText -Force
  New-LocalUser -Name $userName -Description "$($cloudName) automatic robot deployment" -Password $userPassword
  Add-LocalGroupMember -Group "Administrators" -Member $userName
}

function Add-UiPathRobotUser ($session, $userName, $robotUserName) {
  
  if ($robotType -eq "Unattended") {
    $dataUser = @{
      UserName                    = "$($cloudName)-$($userName)"
      Type                        = 'User'
      RolesList                   = @("Allow to be Automation User")
      MayHaveRobotSession         = $true
      MayHaveUnattendedSession    = $true
      MayHaveUserSession          = $true
      MayHavePersonalWorkspace    = $false
      BypassBasicAuthRestriction  = $false
      UnattendedRobot             = @{
        UserName          = "$robotUserName"
        Password          = $machinePassword
        CredentialType    = $credType
        ExecutionSettings = @{ }
      }
      IsExternalLicensed          = $false
      RestrictToPersonalWorkspace = $false
    } | ConvertTo-Json -Depth 3
  }
  else {
    if ($robotType -eq "Attended") {
      $dataUser = @{
        UserName                    = "$($cloudName)-$($userName)"
        Type                        = 'User'
        RolesList                   = @("Allow to be Automation User")
        MayHaveRobotSession         = $true
        MayHaveUnattendedSession    = $false
        MayHaveUserSession          = $true
        MayHavePersonalWorkspace    = $false
        BypassBasicAuthRestriction  = $false
        RobotProvision              = @{
          UserName          = "$robotUserName"
          RobotType         = "$robotType"
          ExecutionSettings = @{ }
        }
        IsExternalLicensed          = $false
        RestrictToPersonalWorkspace = $false
        LicenseType                 = "Attended"
      } | ConvertTo-Json -Depth 3
    }
    else {
      Write-Error "Unknown robot type $robotType"
      Exit 1
    }
  }

  $orchUsers = "$orchestratorUrl/odata/Users"
  Invoke-RestMethod -Uri $orchUsers -Method Post -Body $dataUser -ContentType "application/json" -UseBasicParsing -WebSession $session
}

function Add-UiPathMachineTemplate ($session, $templateName) {

  $orchMachines = "$orchestratorUrl/odata/Machines"
  $getMachines = Invoke-RestMethod -Uri "$orchMachines`?`$filter=Name eq `'$($templateName)`'" `
    -Method GET `
    -ContentType "application/json" `
    -UseBasicParsing `
    -WebSession $websession

  if ($getMachines.'@odata.count' -gt 0) {
    $key = $getMachines.value.LicenseKey
  }
  else {
    $dataMachineTemplate = @{
      Name                = $templateName
      Type                = "Template"
      LicenseKey          = $null
      NonProductionSlots  = 0
      UnattendedSlots     = 0
      TestAutomationSlots = 0
      HeadlessSlots       = 0
      Description         = "This template is automatically generated by the $($cloudName) Robot deployment"
    } | ConvertTo-Json -Depth 3

    try {
      $createMachineTemplate = Invoke-RestMethod -Uri "$orchMachines" `
        -Method POST `
        -Body $dataMachineTemplate `
        -ContentType "application/json" `
        -UseBasicParsing `
        -WebSession $websession

      $key = $createMachineTemplate.LicenseKey
    }
    catch {
      if ($_.ErrorDetails.Message.Contains("already taken")) {
        $getMachines = Invoke-RestMethod -Uri "$orchMachines`?`$filter=Name eq `'$templateName`'" `
          -Method GET `
          -ContentType "application/json" `
          -UseBasicParsing `
          -WebSession $websession
        $key = $getMachines.value.LicenseKey
      }
      else { 
        Write-Error "An error was encountered when trying to performing the REST API call to add the machine template."
        Exit 1 
      }
    }
  }
  return $key
}

function Add-UserToFolder ($session, $folderName, $userName) {

  $orchUsers = "$orchestratorUrl/odata/Users`?`$filter=UserName eq `'$($cloudName)-$($userName)`'"
  $getUsers = Invoke-RestMethod -Uri $orchUsers `
    -Method Get `
    -ContentType "application/json" `
    -UseBasicParsing `
    -WebSession $session

  $orchRole = "$orchestratorUrl/odata/Roles`?`$filter=Name eq `'Automation User`'"
  $getRole = Invoke-RestMethod -Uri $orchRole `
    -Method Get `
    -ContentType "application/json" `
    -UseBasicParsing `
    -WebSession $session

  $orchFolders = "$orchestratorUrl/odata/Folders"
  $getFolders = Invoke-RestMethod -Uri "$orchFolders`?`$filter=DisplayName eq `'$folderName`'" `
    -Method GET `
    -ContentType "application/json" `
    -UseBasicParsing `
    -WebSession $session

  if (($getUsers.'@odata.count' -eq 0) -or ($getRole.'@odata.count' -eq 0) -or ($getFolders.'@odata.count' -eq 0)) {
    Write-Error "Cannot assign users to folders. Exiting..."
    Exit 1
  }

  $dataAssignUserToFolder = @{
    assignments = @{
      UserIds        = @($getUsers.value.Id)
      RolesPerFolder = @(@{
          FolderId = $getFolders.value.Id
          RoleIds  = @($getRole.value.Id)
        })
    }
  } | ConvertTo-Json -Depth 10
  $orchUsers = "$orchestratorUrl/odata/Folders/UiPath.Server.Configuration.OData.AssignUsers"
  Invoke-RestMethod -Uri $orchUsers `
    -Body $dataAssignUserToFolder `
    -Method Post `
    -ContentType "application/json" `
    -UseBasicParsing `
    -WebSession $session
}

function Add-MachineTemplateToFolder ($session, $folderName, $templateName) {

  $orchMachines = "$orchestratorUrl/odata/Machines"
  $getMachines = Invoke-RestMethod -Uri "$orchMachines`?`$filter=Name eq `'$($templateName)`'" `
    -Method GET `
    -ContentType "application/json" `
    -UseBasicParsing `
    -WebSession $websession

  $orchFolders = "$orchestratorUrl/odata/Folders"
  $getFolders = Invoke-RestMethod -Uri "$orchFolders`?`$filter=DisplayName eq `'$folderName`'" `
    -Method GET `
    -ContentType "application/json" `
    -UseBasicParsing `
    -WebSession $session

  if (($getMachines.'@odata.count' -eq 0) -or ($getFolders.'@odata.count' -eq 0)) {
    Write-Error "Cannot assign machines to folders. Continuing..."
    return
  }

  $dataAssignMachineToFolder = @{
    assignments = @{
      MachineIds = @($getMachines.value.Id)
      FolderIds  = @($getFolders.value.Id)
    }
  } | ConvertTo-Json -Depth 10

  $orchUsers = "$orchestratorUrl/odata/Folders/UiPath.Server.Configuration.OData.AssignMachines"
  try {
    Invoke-RestMethod -Uri $orchUsers `
      -Body $dataAssignMachineToFolder `
      -Method Post `
      -ContentType "application/json" `
      -UseBasicParsing `
      -WebSession $session
  }
  catch {
    if ($_.ErrorDetails.Message.Contains("already exists")) {
      #The template is already associated with the folder
      return
    }
    else { 
      Write-Error "Unhandled error: $($_.ErrorDetails.Message)"
      Exit 1 
    }
  }
}

<#
  .DESCRIPTION
  Wait for Robots service to start. This should be used on Citrix Environment, Non-Persistent VDI.

  .PARAMETER servicesName
  Name of the service which should be Running Stopped.

  .PARAMETER serviceStatus
  Status of the defined service.

#>
function Wait-Service($servicesName) {
  # Get all services where DisplayName matches $serviceName and loop through each of them.
  foreach ($service in (Get-Service -DisplayName $servicesName)) {
    Start-Service $service.Name
    # Wait for the service to reach the $serviceStatus or a maximum of specified time
    $service.WaitForStatus('Running', '00:01:20')
  }
}
<#
  .DESCRIPTION
  Installs an MSI by calling msiexec.exe, with verbose logging

  .PARAMETER msiPath
  Path to the MSI to be installed

  .PARAMETER logPath
  Path to a file where the MSI execution will be logged via "msiexec [...] /lv*"

  .PARAMETER features
  A list of features that will be installed via ADDLOCAL="..."

  .PARAMETER properties
  Additional MSI properties to be passed to msiexec
#>
function Invoke-MSIExec {

  param (
    [Parameter(Mandatory = $true)]
    [string] $msiPath,

    [Parameter(Mandatory = $true)]
    [string] $logPath,

    [string[]] $features,

    [System.Collections.Hashtable] $properties
  )

  if (!(Test-Path $msiPath)) {
    throw "No .msi file found at path '$msiPath'"
  }

  $msiExecArgs = "/i `"$msiPath`" /q /lv* `"$logPath`" "

  if ($features) {
    $msiExecArgs += "ADDLOCAL=`"$($features -join ',')`" "
  }

  if ($properties) {
    $msiExecArgs += (($properties.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join " ")
  }

  $process = Start-Process "msiexec" -ArgumentList $msiExecArgs -Wait -PassThru

  return $process
}

<#
  .DESCRIPTION
  Gets the path to the UiRobot.exe file

  .PARAMETER community
  Whether to search for the UiPath Studio Community edition executable
#>
function Get-UiRobotExePath {
  
  $robotExePath = [System.IO.Path]::Combine(${ENV:ProgramFiles(x86)}, "UiPath", "Studio", "UiRobot.exe")
  if ((Test-Path $robotExePath)) {
    return $robotExePath
  }
  $robotExePath = [System.IO.Path]::Combine(${ENV:ProgramFiles}, "UiPath", "Studio", "UiRobot.exe")
  if ((Test-Path $robotExePath)) {
    return $robotExePath
  }
  Write-Error "UiPath Robot was not installed properly, exiting..."
  Exit 1
}

function Test-UiRobotExePath {
  
  $robotExePath = [System.IO.Path]::Combine(${ENV:ProgramFiles(x86)}, "UiPath", "Studio", "UiRobot.exe")
  if ((Test-Path $robotExePath)) {
    Write-Error "Robot 32 bit executable already exists, exiting..."
    Exit 1
  }
  $robotExePath = [System.IO.Path]::Combine(${ENV:ProgramFiles}, "UiPath", "Studio", "UiRobot.exe")
  if ((Test-Path $robotExePath)) {
    Write-Error "Robot 64 bit executable already exists, exiting..."
    Exit 1
  }
}

<#
  .DESCRIPTION
  Install UiPath Robot and/or Studio.

  .PARAMETER msiPath
  MSI installer path.

  .PARAMETER installationFolder
  Installation folder location.

  .PARAMETER robotInstallType
  Robot installation type.
  #>
function Install-RobotWithMSI {

  param (
    [Parameter(Mandatory = $true)]
    [string] $msiPath,

    [string] $installationFolder,

    [string] $robotInstallType
  )

  Write-Output "Installing UiPath Robot Type: $robotInstallType"
  if ($robotInstallType -eq "Unattended") {
    $msiFeatures = @("DesktopFeature", "Robot", "StartupLauncher", "RegisterService", "Packages")
  }
  else {
    if ($robotInstallType -eq "Attended") {
      $msiFeatures = @("DesktopFeature", "Robot", "Studio", "StartupLauncher", "RegisterService", "Packages")
    }
    else {
      Write-Error "Unknown robot type"
      Exit 1
    }
        
  }
  $msiProperties = @{ }
  if ($installationFolder) {
    $msiProperties["APPLICATIONFOLDER"] = $installationFolder;
  }
  $logFile = Join-Path $script:workDirectory "RobotMsiInstall.log"
  Write-Output "Installing UiPath Robot using MSI. Log file is: $logFile"
  Invoke-MSIExec -msiPath $msiPath -logPath $logFile -features $msiFeatures -ErrorAction Stop
}

Main
Stop-Transcript
