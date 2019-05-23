[CmdletBinding()]

param(

    [Parameter()]
    [ValidateSet('19.4.3','19.4.2', '18.4.5', '18.4.4', '18.4.3', '18.4.2', '18.4.1')]
    [string]
    $OrchestratorVersion = "19.4.3",

    [string]
    $hostname,

    [Parameter(Mandatory = $true)]
    [string]
    $dbServerName,

    [Parameter(Mandatory = $true)]
    [string]
    $dbName,

    [Parameter(Mandatory = $true)]
    [string]
    $dbUserName,

    [Parameter(Mandatory = $true)]
    [string]
    $dbPassword,

    [Parameter(Mandatory = $true)]
    [string]
    $orchestratorAdminPassword

)

# Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"
# Script Version
$sScriptVersion = "1.0"
# Debug mode; $true - enabled ; $false - disabled
$sDebug = $true
# Log File Info
$sLogPath = "C:\temp\log\"
$sLogName = "Install-UiPathOrchestrator.log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

function Main {
    try {
        Start-Transcript -Path C:\temp\log\Install-UipathOrchestrator-Transcript.ps1.txt -Append

        # Setup temp dir in %appdata%\Local\Temp
        $tempDirectory = (Join-Path 'C:\temp\' "UiPath-$(Get-Date -f "yyyyMMddhhmmssfff")")
        New-Item -ItemType Directory -Path $tempDirectory -Force

        $source = @()
        $source += "https://download.uipath.com/versions/$OrchestratorVersion/UiPathOrchestrator.msi"
        $source += "https://download.microsoft.com/download/C/9/E/C9E8180D-4E51-40A6-A9BF-776990D8BCA9/rewrite_amd64.msi"
        $source += "http://www.uipath.com/hubfs/server/AddServerRolesAndFeatures.zip"

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
                    Write-Verbose "Failed download. Retrying again in 5 seconds"
                    Start-Sleep 5
                }
            }
        }
    }
    catch {
        Write-Verbose "$($_.exception.message)@ $(Get-Date)"
    }

    if (!$hostname) { $hostname = $env:COMPUTERNAME }

    #unzip AddServerRolesAndFeatures.zip
    unzipArchive -File "$tempDirectory\AddServerRolesAndFeatures.zip" -Destination "$tempDirectory"


    #install windows features
    Install-WindowsFeature -ConfigurationFilePath "$tempDirectory\RolesAndFeatures.xml" -ComputerName "$env:COMPUTERNAME"

    #install URLrewrite
    Start-Process "$tempDirectory\rewrite_amd64.msi" '/qn' -PassThru | Wait-Process

    # New-SelfSignedCertificate -DnsName $hostname -CertStoreLocation cert:\LocalMachine\My

    $cert = New-SelfSignedCertificate -DnsName "$env:COMPUTERNAME", "$hostname" -CertStoreLocation cert:\LocalMachine\My -FriendlyName "Orchestrator Self-Signed certificate" -KeySpec Signature -HashAlgorithm SHA256 -KeyExportPolicy Exportable  -NotAfter (Get-Date).AddYears(20)

    $thumbprint = $cert.Thumbprint

    Export-Certificate -Cert cert:\localmachine\my\$thumbprint -FilePath "$($tempDirectory)\OrchPublicKey.cer" -force

    Import-Certificate -FilePath "$($tempDirectory)\OrchPublicKey.cer" -CertStoreLocation "cert:\LocalMachine\Root"

    #install Orchestrator

    $orchParams = @(
        "/i"
        "$($tempDirectory)\UiPathOrchestrator.msi",
        "ADDLOCAL=OrchestratorFeature",
        "ORCHESTRATORFOLDER=C:\UiPathOrchestrator",
        "APPPOOL_IDENTITY_TYPE=APPPOOLIDENTITY",
        "DB_SERVER_NAME=$($dbServerName)",
        "DB_DATABASE_NAME=$($dbName)",
        "DB_AUTHENTICATION_MODE=SQL",
        "DB_USER_NAME=$($dbUserName)",
        "DB_PASSWORD=$($dbPassword)",
        "HOSTADMIN_PASSWORD=$($orchestratorAdminPassword)",
        "DEFAULTTENANTADMIN_PASSWORD=$($orchestratorAdminPassword)",
        "/qn",
        "/norestart",
        "/l*vx"
        "$($sLogPath)\Install-UiPathOrchestrator.log"
    )


    Start-Process 'msiexec.exe' -ArgumentList $orchParams -Wait -NoNewWindow -PassThru

    #add public DNS to bindings
    New-WebBinding -Name "UiPath*" -IPAddress "*" -Protocol https -HostHeader "$hostname"

    #stopping default website
    Set-ItemProperty "IIS:\Sites\Default Web Site" serverAutoStart False
    Stop-Website 'Default Web Site'

    # Remove temp directory
    Log-Write -LogPath $sLogFile -LineValue "Removing temp directory $($tempDirectory)"
    Remove-Item $tempDirectory -Recurse -Force | Out-Null

}

function unzipArchive {

    param(
        [string]
        $File,

        [string]
        $Destination,

        [switch]
        $ForceCOM
    )


    If (-not $ForceCOM -and ($PSVersionTable.PSVersion.Major -ge 3) -and
        ((Get-ItemProperty -Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue).Version -like "4.5*" -or
            (Get-ItemProperty -Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Client" -ErrorAction SilentlyContinue).Version -like "4.5*")) {
        Write-Verbose -Message "Attempting to Unzip $File to location $Destination using .NET 4.5"
        try {
            [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$File", "$Destination")
        }
        catch {
            Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message"
        }
    }
    else {
        Write-Verbose -Message "Attempting to Unzip $File to location $Destination using COM"
        try {
            $shell = New-Object -ComObject Shell.Application
            $shell.Namespace($destination).copyhere(($shell.NameSpace($file)).items())
        }
        catch {
            Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message"
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
        Add-Content -Path $sFullPath -Value "Running with debug mode [$sDebug]."
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
        Write-Debug "Running with debug mode [$sDebug]."
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
