[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [String] $orchestratorUrl,
    [Parameter(Mandatory = $true)]
    [String] $Tennant,
    [Parameter(Mandatory = $true)]
    [String] $orchAdmin,
    [Parameter(Mandatory = $true)]
    [String] $orchPassword,
    [Parameter(Mandatory = $true)]
    [string] $adminUsername,
    [Parameter()]
    [AllowEmptyString()]
    [string] $machineName,
    [Parameter()]
    [AllowEmptyString()]
    [string] $machinePassword,
    [Parameter()]
    [ValidateSet("Standard", "Floating")]
    [string] $HostingType = "Standard",
    [Parameter(Mandatory = $true)]
    [ValidateSet("Unattended", "Attended", "Development", "Nonproduction")]
    [string] $RobotType,
    [Parameter()]
    [AllowEmptyString()]
    [string] $credType = "Default",
    [Parameter()]
    [AllowEmptyString()]
    [string] $robotArtifact = "https://download.uipath.com/UiPathStudio.msi",
    [Parameter()]
    [AllowEmptyString()]
    [string]$artifactFileName = "UiPathStudio.msi",
    [Parameter()]
    [ValidateSet("Yes", "No")]
    [string]$addRobotsToExistingEnvs = "No"

)
#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"
#Script Version
$sScriptVersion = "1.0"
#Debug mode; $true - enabled ; $false - disabled
$sDebug = $true
#Log File Info
$sLogPath = "C:\Windows\Temp"
$sLogName = "Install-UiPathRobot.log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName
#Orchestrator SSL check
$orchSSLcheck = $false

function Main {

    Begin {

        #Log log log
        Log-Write -LogPath $sLogFile -LineValue "Install-UiRobot starts"

        #Define TLS for Invoke-WebRequest
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        if (!$orchSSLcheck) {

            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

        }

        #Setup temp dir in %appdata%\Local\Temp
        $script:tempDirectory = (Join-Path $ENV:TEMP "UiPath-$(Get-Date -f "yyyyMMddhhmmssfff")")
        New-Item -ItemType Directory -Path $script:tempDirectory | Out-Null

        #Download UiPlatform
        $msiPath = Join-Path $script:tempDirectory $artifactFileName

        $maxAttempts = 5 #set the maximum number of attempts in case the download will never succeed.

        $attemptCount = 0

        Do {

            $attemptCount++
            Download-File -url $robotArtifact -outputFile $msiPath

        } while (((Test-Path $msiPath) -eq $false) -and ($attemptCount -le $maxAttempts))


    }

    Process {

        #Get Robot path
        $robotExePath = Get-UiRobotExePath

        if (!(Test-Path $robotExePath)) {

            #Log log log
            Log-Write -LogPath $sLogFile -LineValue "Installing UiPath Robot Type [$RobotType]"

            #Install the Robot
            if ($RobotType -eq "Unattended") {
                # log log log
                Log-Write -LogPath $sLogFile -LineValue "Installing UiPath Robot without Studio Feature"
                $msiFeatures = @("DesktopFeature", "Robot", "StartupLauncher", "RegisterService", "Packages")
            }
            else {
                # log log log
                Log-Write -LogPath $sLogFile -LineValue "Installing UiPath Robot with Studio Feature"
                $msiFeatures = @("DesktopFeature", "Robot", "Studio", "StartupLauncher", "RegisterService", "Packages")
            }

            Try {
                $installResult = Install-Robot -msiPath $msiPath -msiFeatures $msiFeatures
            }

            Catch {
                Log-Error -LogPath $sLogFile -ErrorDesc $_.Exception -ExitGracefully $True
                Break
            }

            #End of the Robot installation

        }


        Try {

            $dataLogin = @{
                tenancyName            = $Tennant
                usernameOrEmailAddress = $orchAdmin
                password               = $orchPassword
            } | ConvertTo-Json

            $orchUrl_login = "$orchestratorUrl/account/login"

            # login API call to get the login session used for all requests
            $orchWebResponse = Invoke-RestMethod -Uri $orchUrl_login -Method Post -Body $dataLogin -ContentType "application/json" -UseBasicParsing -Session websession

            # log log log
            if ($sDebug) {
                Log-Write -LogPath $sLogFile -LineValue "Logging Orchestrator Web Response"
                Log-Write -LogPath $sLogFile -LineValue $orchWebResponse
            }

        }
        Catch {

            Log-Error -LogPath $sLogFile -ErrorDesc $orchWebResponse -ExitGracefully $True
            Break
        }

        Try {
            # new Machine Name
            if (!$machineName) {
                $machineName = $env:computername   
            }

            #Provision Robot Type to Orchestrator
            if ($RobotType -eq "Unattended" -or "Development") {
                $dataRobot = @{
                    MachineName       = $machineName
                    Username          = $adminUsername
                    Type              = $RobotType
                    HostingType       = $HostingType
                    Password          = $machinePassword
                    CredentialType    = $credType
                    Name              = $machineName
                    ExecutionSettings = @{ }
                } | ConvertTo-Json
            }
            else {
                $dataRobot = @{
                    MachineName       = $machineName
                    Username          = $adminUsername
                    Type              = $RobotType
                    HostingType       = $HostingType
                    Name              = $machineName
                    ExecutionSettings = @{ }
                } | ConvertTo-Json
            }

            $orch_bot = "$orchestratorUrl/odata/Robots"
            $botWebResponse = Invoke-RestMethod -Uri $orch_bot -Method Post -Body $dataRobot -ContentType "application/json" -UseBasicParsing -WebSession $websession

            #Log log log
            if ($sDebug) {
                Log-Write -LogPath $sLogFile -LineValue "Logging Orchestrator Bot Web Response"
                Log-Write -LogPath $sLogFile -LineValue $botWebResponse
            }



        }
        Catch {

            $addExceptionMsg = $_.Exception.Message
            Log-Error -LogPath $sLogFile -ErrorDesc $botWebResponse -ExitGracefully $True
            Break
        }

        Finally {



            #Starting Robot
            start-process -filepath $robotExePath -verb runas

            $waitForRobotSVC = waitForService "UiPath Robot*" "Running"


            if ($addExceptionMsg) {

                #Log log log
                if ($sDebug) {
                    Log-Write -LogPath $sLogFile -LineValue "Robot [$machineName] already exists, trying to connect to [$orchestratorUrl]"
                }

                $orchMachines = "$orchestratorUrl/odata/Machines"

                $getbotWebResponse = Invoke-RestMethod -Uri $orchMachines -Method GET -ContentType "application/json" -UseBasicParsing -WebSession $websession


                $existingRobot = $getbotWebResponse.value | Where-Object { $_.Name -eq $machineName } | Select-Object -ExpandProperty id

                $getMachineLicense = "$orchestratorUrl/odata/Machines($existingRobot)"

                $getMachineLicenseWebResponse = Invoke-RestMethod -Uri $getMachineLicense -Method GET -ContentType "application/json" -UseBasicParsing -WebSession $websession


                $key = $getMachineLicenseWebResponse.LicenseKey

            }
            else {

                #Get Robot key
                $key = $botWebResponse.LicenseKey

            }

            if ((Get-Service UiRobotSvc | Select Status) -eq "Running") {

                # Connect Robot to Orchestrator with Robot key
                $connectRobot = & $robotExePath --connect -url  $orchestratorUrl -key $key

            }

            # Create a task to automatically add Robot to Orchestrator. For AWS because of launch state.
            $createRobotTask = robotTask -robotPath $robotExePath -orcURL $orchestratorUrl -robotKey $key

            #Log
            Log-Write -LogPath $sLogFile -ErrorDesc $waitForRobotSVC -ExitGracefully $True
            Log-Write -LogPath $sLogFile -ErrorDesc $createRobotTask -ExitGracefully $True
            Log-Error -LogPath $sLogFile -ErrorDesc $connectRobot -ExitGracefully $True

            #Remove temp directory
            Log-Write -LogPath $sLogFile -LineValue "Removing temp directory $($script:tempDirectory)"
            Remove-Item $script:tempDirectory -Recurse -Force | Out-Null

        }
    
        if ($addRobotsToExistingEnvs -eq "Yes") {
      
            #add Robot to existing Envs
            $getOdataEnv = "$orchestratorUrl/odata/Environments"

            $getOdataEnvironment = Invoke-RestMethod -Uri $getOdataEnv -Method Get -ContentType "application/json" -UseBasicParsing -WebSession $websession

            foreach ($roEnv in $getOdataEnvironment.value.Id) {

                $roEnvURL = "$orchestratorUrl/odata/Environments($($roEnv))/UiPath.Server.Configuration.OData.AddRobot"

                $dataRobotEnv = @{
                    robotId = "$($botWebResponse.Id)"
                } | ConvertTo-Json

                $botToEnvironment = Invoke-RestMethod -Uri $roEnvURL -Method Post -Body $dataRobotEnv -ContentType "application/json" -UseBasicParsing -WebSession $websession

            }

        }


    }

    End {

        If ($?) {
            Log-Write -LogPath $sLogFile -LineValue "Completed Successfully."
            Log-Write -LogPath $sLogFile -LineValue " "
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
function waitForService($servicesName, $serviceStatus) {

    # Get all services where DisplayName matches $serviceName and loop through each of them.
    foreach ($service in (Get-Service -DisplayName $servicesName)) {
        if ($serviceStatus -eq 'Running') {
            Start-Service $service.Name
        }
        if ($serviceStatus -eq "Stopped" ) {
            Stop-Service $service.Name
        }
        # Wait for the service to reach the $serviceStatus or a maximum of specified time
        $service.WaitForStatus($serviceStatus, '00:01:20')
    }

    return $serviceStatus

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

    param(
        [switch] $community
    )

    $robotExePath = [System.IO.Path]::Combine(${ENV:ProgramFiles(x86)}, "UiPath", "Studio", "UiRobot.exe")

    if ($community) {
        $robotExePath = Get-ChildItem ([System.IO.Path]::Combine($ENV:LOCALAPPDATA, "UiPath")) -Recurse -Include "UiRobot.exe" | `
            Select-Object -ExpandProperty FullName -Last 1
    }

    return $robotExePath
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
  .DESCRIPTION
  Install UiPath Robot and/or Studio.

  .PARAMETER msiPath
  MSI installer path.

  .PARAMETER installationFolder
  Installation folder location.

  .PARAMETER msiFeatures
  MSI features : Robot with or without Studio
  #>
function Install-Robot {

    param (
        [Parameter(Mandatory = $true)]
        [string] $msiPath,

        [string] $installationFolder,

        [string[]] $msiFeatures
    )

    if (!$msiProperties) {
        $msiProperties = @{ }
    }


    if ($installationFolder) {
        $msiProperties["APPLICATIONFOLDER"] = $installationFolder;
    }

    $logPath = Join-Path $script:tempDirectory "install.log"

    Write-Verbose "Installing UiPath"

    $process = Invoke-MSIExec -msiPath $msiPath -logPath $logPath -features $msiFeatures

    return @{
        LogPath        = $logPath;
        MSIExecProcess = $process;
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

        #Check if file exists and delete if it does
        If ((Test-Path -Path $sFullPath)) {
            Remove-Item -Path $sFullPath -Force
        }

        #Create file and start logging
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

        #Write to screen for debug mode
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

        #Write to screen for debug mode
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

        #Write to screen for debug mode
        Write-Debug "Error: An error has occurred [$ErrorDesc]."

        #If $ExitGracefully = True then run Log-Finish and exit script
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

        #Write to screen for debug mode
        Write-Debug ""
        Write-Debug "***************************************************************************************************"
        Write-Debug "Finished processing at [$([DateTime]::Now)]."
        Write-Debug "***************************************************************************************************"
        Write-Debug ""

        #Exit calling script if NoExit has not been specified or is set to False
        If (!($NoExit) -or ($NoExit -eq $False)) {
            Exit
        }
    }
}

function robotTask {
    param (
        [Parameter(Mandatory = $true)]
        [string] $robotPath,

        [Parameter(Mandatory = $true)]
        [string] $orcURL,

        [Parameter(Mandatory = $true)]
        [string] $robotKey

    )

    $STAction = @()
    # Set up action to run
    $STAction += New-ScheduledTaskAction `
        -Execute 'NET' `
        -Argument 'START "UiRobotSvc"'

    $STAction += New-ScheduledTaskAction `
        -Execute "$robotPath" `
        -Argument "--connect -url  $orcURL -key $robotKey"

    # Set up trigger to launch action
    $STTrigger = New-ScheduledTaskTrigger `
        -Once `
        -At ([DateTime]::Now.AddMinutes(1)) `
        -RepetitionInterval (New-TimeSpan -Minutes 2) `
        -RepetitionDuration (New-TimeSpan -Minutes 10)

    # Set up base task settings - NOTE: Win8 is used for Windows 10
    $STSettings = New-ScheduledTaskSettingsSet `
        -Compatibility Win8 `
        -MultipleInstances IgnoreNew `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -Hidden `
        -StartWhenAvailable

    # Name of Scheduled Task
    $STName = "UiPathRobot"

    # Create Scheduled Task
    Register-ScheduledTask `
        -Action $STAction `
        -Trigger $STTrigger `
        -Settings $STSettings `
        -TaskName $STName `
        -Description "Executes Machine Policy Retrieval Cycle." `
        -User "NT AUTHORITY\SYSTEM" `
        -RunLevel Highest

    # Get the Scheduled Task data and make some tweaks
    $TargetTask = Get-ScheduledTask -TaskName $STName

    # Set desired tweaks
    $TargetTask.Author = 'UiPath'
    $TargetTask.Triggers[0].StartBoundary = [DateTime]::Now.ToString("yyyy-MM-dd'T'HH:mm:ss")
    $TargetTask.Triggers[0].EndBoundary = [DateTime]::Now.AddMinutes(3).ToString("yyyy-MM-dd'T'HH:mm:ss")
    $TargetTask.Settings.AllowHardTerminate = $True
    $TargetTask.Settings.DeleteExpiredTaskAfter = 'PT5S'
    $TargetTask.Settings.ExecutionTimeLimit = 'PT10M'
    $TargetTask.Settings.volatile = $False

    # Save tweaks to the Scheduled Task
    $TargetTask | Set-ScheduledTask

}

Log-Start -LogPath $sLogPath -LogName $sLogName -ScriptVersion $sScriptVersion
Main
Log-Finish -LogPath $sLogFile
