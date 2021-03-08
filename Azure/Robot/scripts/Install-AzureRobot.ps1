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

$logFile = "InstallationWrapper.log"
Start-Transcript -Path $logFile -Append -IncludeInvocationHeader
$ErrorActionPreference = "Stop"
function Main {
    $telemetryGuid = New-Guid
    $telemetryProps = @{
        ID = $telemetryGuid;
        status = 'ConfigurationStarting';
    }
    $azureUtilsFile = "./AzureUtils.psm1"
    if ((Test-Path $azureUtilsFile)) {
        Import-Module $azureUtilsFile
        Send-TelemetryToInsights -name 'Robot' -properties $telemetryProps
    }

    InstallRobot

    if ((Test-Path $azureUtilsFile)) {
        Import-Module $azureUtilsFile
        $telemetryProps.status = 'ConfigurationFinished'
        Send-TelemetryToInsights -name 'Robot' -properties $telemetryProps
    }
}

function InstallRobot {
    Write-Output "******* $(Get-Date) Started UiPath Robot installation ******* "
    
    .\Install-UiPathRobots.ps1 `
        -artifactFileName $artifactFileName `
        -orchestratorUrl $orchestratorUrl `
        -tenant $tenant `
        -orchAdmin $orchAdmin `
        -orchPassword $orchPassword `
        -hostingType $hostingType `
        -robotType $robotType `
        -machineAdminUsername $machineAdminUsername `
        -machinePassword $machinePassword `
        -credType $credType `
        -cloudName $cloudName
    
    Write-Output "******* $(Get-Date) Finished installing UiPath Robot ******* "
}

Main
Stop-Transcript
