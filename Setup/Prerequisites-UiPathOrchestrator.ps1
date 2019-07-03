[CmdletBinding()]

param(

    [Parameter()]
    [ValidateSet('19.4.3', '19.4.2', '18.4.6', '18.4.5', '18.4.4', '18.4.3', '18.4.2', '18.4.1')]
    [string]
    $orchestratorVersion = "19.4.3"

)

# Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"
# Script Version
$sScriptVersion = "1.0"
# Log File Info
$sLogPath = "C:\temp\"
$sLogName = "Install-OrchestratorFeatures.log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

function Main {
    
    try {
        # Setup temp dir in %appdata%\Local\Temp
        $tempDirectory = (Join-Path 'C:\temp\' "UiPath-$(Get-Date -f "yyyyMMddhhmmssfff")")
        New-Item -ItemType Directory -Path $tempDirectory -Force

        $source = @()
        $source += "https://download.uipath.com/versions/$orchestratorVersion/UiPathOrchestrator.msi"
        $source += "https://download.microsoft.com/download/C/9/E/C9E8180D-4E51-40A6-A9BF-776990D8BCA9/rewrite_amd64.msi"

        $tries = 5
        while ($tries -ge 1) {
            try {
                foreach ($item in $source) {

                    $package = $item.Substring($item.LastIndexOf("/") + 1)

                    Download-File -url "$item " -outputFile "$tempDirectory\$package"

                    # Start-BitsTransfer -Source $item -Destination "$tempDirectory" -ErrorAction Stop

                }
                break
            }
            catch {
                $tries--
                Write-Verbose "Exception:"
                Write-Verbose "$_"
                if ($tries -lt 1) {
                    throw $_
                }
                else {
                    Write-Verbose
                    Log-Write -LogPath $sLogFile -LineValue "Failed download. Retrying again in 5 seconds"
                    Start-Sleep 5
                }
            }
        }
    }
    catch {

        Log-Error -LogPath $sLogFile -ErrorDesc "$($_.exception.message) on $(Get-Date)" -ExitGracefully $True

    }

    $features = @(
        'IIS-DefaultDocument',
        'IIS-HttpErrors',
        'IIS-StaticContent',
        'IIS-RequestFiltering',
        'IIS-CertProvider',
        'IIS-IPSecurity',
        'IIS-URLAuthorization',
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

        $checkFeature = Get-WindowsFeature "IIS-DirectoryBrowsing"
        if ( $checkFeature.Installed -eq $true) {
            Disable-WindowsOptionalFeature -FeatureName IIS-DirectoryBrowsing -Remove -NoRestart -Online
            Log-Write -LogPath $sLogPath -LineValue "Feature IIS-DirectoryBrowsing is removed" 
        }

        Install-UrlRewrite -urlRWpath "$tempDirectory\rewrite_amd64.msi"

    }
    catch {
        Write-Error $_.exception.message
        Log-Error -LogPath $sLogFile -ErrorDesc "$($_.exception.message) installing $feature" -ExitGracefully $True
    }

    Write-Host "Features installed" -ForegroundColor Green

}

<#
    .SYNOPSIS
      Install URL Rewrite necessary for UiPath Orchestrator.

    .PARAMETER urlRWpath
      Mandatory. String. Path to URL Rewrite package. Example: $urlRWpath = "C:\temp\rewrite_amd64.msi"

    .INPUTS
      Parameters above.

    .OUTPUTS
      None
    
    .Example
      Install-UrlRewrite -urlRWpath "C:\temp\rewrite_amd64.msi"
#>
function Install-UrlRewrite {
  
    param(

        [Parameter(Mandatory = $true)]
        [string]
        $urlRWpath

    )

    # Do nothing if URL Rewrite module is already installed
    $rewriteDllPath = Join-Path $Env:SystemRoot 'System32\inetsrv\rewrite.dll'

    if (Test-Path -Path $rewriteDllPath) {
        Log-Write -LogPath $sLogFile -LineValue  "IIS URL Rewrite 2.0 Module is already installed"

        return
    }

    $installer = $urlRWpath

    $exitCode = 0
    $argumentList = "/i `"$installer`" /q /norestart"

    Log-Write -LogPath $sLogFile -LineValue  "Installing IIS URL Rewrite 2.0 Module"

    $exitCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList $argumentList -Wait -Passthru).ExitCode

    if ($exitCode -ne 0 -and $exitCode -ne 1641 -and $exitCode -ne 3010) {
        Log-Error -LogPath $sLogFile -ErrorDesc "Failed to install IIS URL Rewrite 2.0 Module (Exit code: $exitCode)" -ExitGracefully $False
    }
    else {
        Log-Write -LogPath $sLogFile -LineValue  "IIS URL Rewrite 2.0 Module successfully installed"
    }
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
            Log-Write -LogPath $sLogFile -LineValue "Installing feature $feature"
            Write-Verbose "Installing feature $feature"
            Enable-WindowsOptionalFeature -Online -FeatureName $feature -all -NoRestart
        }
        catch {
            Log-Error -LogPath $sLogFile -ErrorDesc "$($_.exception.message) installing $($feature)" -ExitGracefully $True
        }

    }

}

<#
  .DESCRIPTION
  Downloads a file from a URL

  .PARAMETER url
  The URL to download from

  .PARAMETER outputFile
  The local path where the file will be downloaded
#>
function Download-File {

    param (
        [Parameter(Mandatory = $true)]
        [string]$url,

        [Parameter(Mandatory = $true)]
        [string] $outputFile
    )

    Write-Verbose "Downloading file from $url to local path $outputFile"

    Try {
        $webClient = New-Object System.Net.WebClient
    }
    Catch {
        Log-Error -LogPath $sLogFile -ErrorDesc "The following error occurred: $_" -ExitGracefully $True
    }
    Try {
        $webClient.DownloadFile($url, $outputFile)
    }
    Catch {
        Log-Error -LogPath $sLogFile -ErrorDesc "The following error occurred: $_" -ExitGracefully $True
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