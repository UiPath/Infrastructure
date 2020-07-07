[CmdletBinding()]


# Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"
# Script Version
$sScriptVersion = "1.0"
# Log File Info
$sLogPath = ".\"
$sLogName = "Install-OrchestratorFeatures.log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

function Main {
    

    $features = @(
        'IIS-DefaultDocument',
        'IIS-HttpErrors',
        'IIS-StaticContent',
        'IIS-RequestFiltering',
        'IIS-CertProvider',
        'IIS-IPSecurity',
        'IIS-URLAuthorization',
        'IIS-ApplicationInit',
        'IIS-WindowsAuthentication',
        'IIS-NetFxExtensibility45',
        'IIS-ASPNET45',
        'IIS-ISAPIExtensions',
        'IIS-ISAPIFilter',
        'IIS-WebSockets',
        'IIS-ManagementConsole',
        'IIS-ManagementScriptingTools',
        'ClientForNFS-Infrastructure'
    )

    try {
    
        Install-UiPathOrchestratorFeatures -features $features

    }
    catch {
        Write-Error $_.exception.message
        Log-Error -LogPath $sLogFile -ErrorDesc "$($_.exception.message) installing $feature" -ExitGracefully $True
    }

    Write-Host "Features installed" -ForegroundColor Green

}

<#
    .SYNOPSIS
      Install necessary Windows Features for UiPath Orchestrator.

    .PARAMETER features
      Mandatory. Array. Windows Features you want to install on the local server. Example: $features = 'ClientForNFS-Infrastructure'

    .INPUTS
      Parameters above.

    .OUTPUTS
      None
    
    .Example
      Install-UiPathOrchestratorFeatures -features  @('IIS-DefaultDocument','WCF-TCP-PortSharing45','ClientForNFS-Infrastructure')
#>
function Install-UiPathOrchestratorFeatures {
    param (

        [Parameter(Mandatory = $true)]
        [string[]] $features

    )

    foreach ($feature in $features) {

        try {
            $state = (Get-WindowsOptionalFeature -FeatureName $feature -Online).State
            Log-Write -LogPath $sLogFile -LineValue "Checking for feature $feature Enabled/Disabled => $state"
            Write-Host "Checking for feature $feature Enabled/Disabled => $state"
			if ($state -ne 'Enabled') {
				Log-Write -LogPath $sLogFile -LineValue "Installing feature $feature"
				Write-Host "Installing feature $feature"
				Enable-WindowsOptionalFeature -Online -FeatureName $feature -all -NoRestart
			}
        }
        catch {
            Log-Error -LogPath $sLogFile -ErrorDesc "$($_.exception.message) installing $($feature)" -ExitGracefully $True
        }

    }

}


<#
  .SYNOPSIS
    Creates log file

  .DESCRIPTION
    Creates log file with path and name that is passed. Checks if log file exists, and if it does deletes it and creates a new one.
    Once created, writes initial logging data

  .PARAMETER LogPath
    Mandatory. Path of where log is to be created. Example: C:\Windows\Temp

  .PARAMETER LogName
    Mandatory. Name of log file to be created. Example: Test_Script.log

  .PARAMETER ScriptVersion
    Mandatory. Version of the running script which will be written in the log. Example: 1.5

  .INPUTS
    Parameters above

  .OUTPUTS
    Log file created
#>
function Log-Start {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)]
        [string]$LogPath,

        [Parameter(Mandatory = $true)]
        [string]$LogName,

        [Parameter(Mandatory = $true)]
        [string]$ScriptVersion
    )

    Process {
        $sFullPath = $LogPath + "\" + $LogName

        # Check if file exists and delete if it does
        If ((Test-Path -Path $sFullPath)) {
            Remove-Item -Path $sFullPath -Force
        }

        # Create file and start logging
        New-Item -Path $LogPath -Value $LogName -ItemType File

        Add-Content -Path $sFullPath -Value "***************************************************************************************************"
        Add-Content -Path $sFullPath -Value "Started processing at [$([DateTime]::Now)]."
        Add-Content -Path $sFullPath -Value "***************************************************************************************************"
        Add-Content -Path $sFullPath -Value ""
        Add-Content -Path $sFullPath -Value "Running script version [$ScriptVersion]."
        Add-Content -Path $sFullPath -Value ""
        Add-Content -Path $sFullPath -Value "***************************************************************************************************"
        Add-Content -Path $sFullPath -Value ""

        # Write to screen for debug mode
        Write-Debug "***************************************************************************************************"
        Write-Debug "Started processing at [$([DateTime]::Now)]."
        Write-Debug "***************************************************************************************************"
        Write-Debug ""
        Write-Debug "Running script version [$ScriptVersion]."
        Write-Debug ""
        Write-Debug "***************************************************************************************************"
        Write-Debug ""
    }

}


<#
    .SYNOPSIS
      Writes to a log file

    .DESCRIPTION
      Appends a new line to the end of the specified log file

    .PARAMETER LogPath
      Mandatory. Full path of the log file you want to write to. Example: C:\Windows\Temp\Test_Script.log

    .PARAMETER LineValue
      Mandatory. The string that you want to write to the log

    .INPUTS
      Parameters above

    .OUTPUTS
      None
#>
function Log-Write {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)]
        [string]$LogPath,

        [Parameter(Mandatory = $true)]
        [string]$LineValue
    )

    Process {
        Add-Content -Path $LogPath -Value $LineValue

        # Write to screen for debug mode
        Write-Debug $LineValue
    }
}

<#
    .SYNOPSIS
      Writes an error to a log file

    .DESCRIPTION
      Writes the passed error to a new line at the end of the specified log file

    .PARAMETER LogPath
      Mandatory. Full path of the log file you want to write to. Example: C:\Windows\Temp\Test_Script.log

    .PARAMETER ErrorDesc
      Mandatory. The description of the error you want to pass (use $_.Exception)

    .PARAMETER ExitGracefully
      Mandatory. Boolean. If set to True, runs Log-Finish and then exits script

    .INPUTS
      Parameters above

    .OUTPUTS
      None
#>
function Log-Error {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)]
        [string]$LogPath,

        [Parameter(Mandatory = $true)]
        [string]$ErrorDesc,

        [Parameter(Mandatory = $true)]
        [boolean]$ExitGracefully
    )

    Process {
        Add-Content -Path $LogPath -Value "Error: An error has occurred [$ErrorDesc]."

        # Write to screen for debug mode
        Write-Debug "Error: An error has occurred [$ErrorDesc]."

        # If $ExitGracefully = True then run Log-Finish and exit script
        If ($ExitGracefully -eq $True) {
            Log-Finish -LogPath $LogPath
            Break
        }
    }
}

<#
    .SYNOPSIS
      Write closing logging data & exit

    .DESCRIPTION
      Writes finishing logging data to specified log and then exits the calling script

    .PARAMETER LogPath
      Mandatory. Full path of the log file you want to write finishing data to. Example: C:\Windows\Temp\Script.log

    .PARAMETER NoExit
      Optional. If this is set to True, then the function will not exit the calling script, so that further execution can occur

    .INPUTS
      Parameters above

    .OUTPUTS
      None
#>
function Log-Finish {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)]
        [string]$LogPath,

        [Parameter(Mandatory = $false)]
        [string]$NoExit
    )

    Process {
        Add-Content -Path $LogPath -Value ""
        Add-Content -Path $LogPath -Value "***************************************************************************************************"
        Add-Content -Path $LogPath -Value "Finished processing at [$([DateTime]::Now)]."
        Add-Content -Path $LogPath -Value "***************************************************************************************************"
        Add-Content -Path $LogPath -Value ""

        # Write to screen for debug mode
        Write-Debug ""
        Write-Debug "***************************************************************************************************"
        Write-Debug "Finished processing at [$([DateTime]::Now)]."
        Write-Debug "***************************************************************************************************"
        Write-Debug ""

        # Exit calling script if NoExit has not been specified or is set to False
        If (!($NoExit) -or ($NoExit -eq $False)) {
            Exit
        }
    }
}


Log-Start -LogPath $sLogPath -LogName $sLogName -ScriptVersion $sScriptVersion
Main
Log-Finish -LogPath $sLogFile
