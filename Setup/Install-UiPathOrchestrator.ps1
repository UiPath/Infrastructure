<#
    .SYNOPSIS
      Install UiPath Orchestrator.

    .Description
      Install UiPath Orchestrator and configure web.config based on a passphrase.

    .PARAMETER orchestratorVersion
      String. Allowed versions: FTS 19.x and LTS 18.4.x . Version of the Orchestrator which will be installed. Example: $orchestratorVersion = "19.4.3"
 
    .PARAMETER hostname
      String. Orchestrator server name, public or private DNS of the server can also be used. Example: $hostname = "serverName"
 
    .PARAMETER dbServerName
      String. Mandatory. SQL server name. Example: $dbServerName = "SQLServerName.local"
 
    .PARAMETER dbName
      String. Mandatory. Database Name. Example: $dbName = "devtestdb"
 
    .PARAMETER dbUserName
      String. Mandatory. Database Username. Example: $dbUserName = "devtestdbuser"
 
    .PARAMETER dbPassword
      String. Mandatory. Database Password  Example: $dbPassword = "d3vt3std@taB@s3!"

    .PARAMETER passphrase
      String. Mandatory. Passphrase is used to generate same AppEncryption key, Nuget API keys, Machine Validation and Decryption keys.  Example: $passphrase = "AnyPassPhrase!@#$"
 
    .PARAMETER redisHost
      String. There is no need to use Redis if there is only one Orchestrator instance. Redis is mandatory in multi-node deployment.  Example: $redisHost = "redishostDNS"
 
    .PARAMETER nuGetStoragePath
      String. Mandatory. Storage Path where the Nuget Packages are saved. Also you can use NFS or SMB share.  Example: $nuGetStoragePath = "\\nfs-share\NugetPackages"

    .PARAMETER orchestratorAdminPassword
      String. Mandatory. Orchestrator Admin password is necessary for a new installation and to change the Nuget API keys. Example: $orchestratorAdminPassword = "P@ssW05D!"
 
    .PARAMETER orchestratorAdminUsername
      String. Orchestrator Admin username in order to change the Nuget API Keys.  Example: $orchestratorAdminUsername = "admin"
 
    .PARAMETER tennant
      String. Orchestrator Tennant in order to change the Nuget API Key.  Example: $tennant = "Default"
 
    .INPUTS
      Parameters above.

    .OUTPUTS
      None
    
    .Example
      powershell.exe -ExecutionPolicy Bypass -File "\\fileLocation\Install-UiPathOrchestrator.ps1" -OrchestratorVersion "19.4.3" -passphrase "AnyPassPhrase!@#$" -dbServerName  "SQLServerName.local"  -dbName "devtestdb"  -dbUserName "devtestdbuser" -dbPassword "d3vt3std@taB@s3!" -orchestratorAdminPassword "P@ssW05D!" -redisHost "redishostDNS" -NuGetStoragePath "\\nfs-share\NugetPackages"
#>
[CmdletBinding()]

param(

    [Parameter()]
    [ValidateSet('19.4.3', '19.4.2', '18.4.6', '18.4.5', '18.4.4', '18.4.3', '18.4.2', '18.4.1')]
    [string]
    $orchestratorVersion = "19.4.3",

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
    $passphrase,

    [string[]]
    $redisHost,

    [Parameter(Mandatory = $true)]
    [string]
    $nuGetStoragePath,

    [Parameter()]
    [string]
    $orchestratorAdminUsername = "admin",

    [Parameter(Mandatory = $true)]
    [string]
    $orchestratorAdminPassword,

    [Parameter()]
    [string]
    $tennant = "Default"

)

# Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"
# Script Version
$sScriptVersion = "1.0"
# Debug mode; $true - enabled ; $false - disabled
$sDebug = $true
# Log File Info
$sLogPath = "C:\temp\log"
$sLogName = "Install-Orchestrator.ps1.log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

function Main {
    try {
        Start-Transcript -Path "$sLogPath\Install-UipathOrchestrator-Transcript.ps1.txt" -Append

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

    if (!$hostname) { $hostname = $env:COMPUTERNAME }

    $features = @(
        'IIS-DefaultDocument',
        'IIS-HttpErrors',
        'IIS-StaticContent',
        'IIS-RequestFiltering',
        'IIS-URLAuthorization',
        'IIS-WindowsAuthentication',
        'IIS-NetFxExtensibility45',
        'IIS-ASPNET45',
        'IIS-ISAPIExtensions',
        'IIS-ISAPIFilter',
        'IIS-WebSockets',
        'IIS-ManagementConsole',
        'IIS-ManagementScriptingTools',
        'WCF-TCP-PortSharing45',
        'ClientForNFS-Infrastructure'
    )
    Install-UiPathOrchestratorFeatures -features $features

    $checkFeature = Get-WindowsFeature "IIS-DirectoryBrowsing"
    if ( $checkFeature.Installed -eq $true) {
        Disable-WindowsOptionalFeature -FeatureName IIS-DirectoryBrowsing -Remove -NoRestart -Online
        Log-Write -LogPath $sLogPath -LineValue "Feature IIS-DirectoryBrowsing is removed" 
    }

    #install URLrewrite
    Install-UrlRewrite -urlRWpath "$tempDirectory\rewrite_amd64.msi"
    Start-Process "$tempDirectory\rewrite_amd64.msi" '/qn' -PassThru | Wait-Process


    # ((Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/public-hostname -UseBasicParsing).RawContent -split "`n")[-1]

    $cert = New-SelfSignedCertificate -DnsName "$env:COMPUTERNAME", "$hostname" -CertStoreLocation cert:\LocalMachine\My -FriendlyName "Orchestrator Self-Signed certificate" -KeySpec Signature -HashAlgorithm SHA256 -KeyExportPolicy Exportable  -NotAfter (Get-Date).AddYears(20)

    $thumbprint = $cert.Thumbprint

    Export-Certificate -Cert cert:\localmachine\my\$thumbprint -FilePath "$($tempDirectory)\OrchPublicKey.cer" -force

    Import-Certificate -FilePath "$($tempDirectory)\OrchPublicKey.cer" -CertStoreLocation "cert:\LocalMachine\Root"

    #install Orchestrator

    $getEncryptionKey = Generate-Key -passphrase $passphrase




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
        "APP_ENCRYPTION_KEY=$($getEncryptionKey.encryptionKey)",
        "APP_NUGET_ACTIVITIES_KEY=$($getEncryptionKey.nugetKey)",
        "APP_NUGET_PACKAGES_KEY=$($getEncryptionKey.nugetKey)",
        "APP_MACHINE_DECRYPTION_KEY=$($getEncryptionKey.DecryptionKey)",
        "APP_MACHINE_VALIDATION_KEY=$($getEncryptionKey.Validationkey)",
        "/qn",
        "/norestart",
        "/l*vx"
        "$($sLogPath)\Install-UiPathOrchestrator.log"
    )


    Start-Process 'msiexec.exe' -ArgumentList $orchParams -Wait -NoNewWindow -PassThru

    #Remove the default Binding
    Remove-WebBinding -Name "Default Web Site" -BindingInformation "*:80:"

    #add public DNS to bindings
    New-WebBinding -Name "UiPath*" -IPAddress "*" -Protocol http
    New-WebBinding -Name "UiPath*" -IPAddress "*" -Protocol https

    #stopping default website
    Set-ItemProperty "IIS:\Sites\Default Web Site" serverAutoStart False
    Stop-Website 'Default Web Site'

    #disable https to http for AWS ELB
    Set-WebConfigurationProperty '/system.webserver/rewrite/rules/rule[@name="Redirect HTTP to HTTPS"]' -Name enabled -Value false -PSPath "IIS:\sites\UiPath Orchestrator"

    #test Orchestrator URL
    try {
        TestOrchestratorConnection -orchestratorURL "https://$hostname"
        TestOrchestratorConnection -orchestratorURL "http://$hostname"
    }
    catch {
        Log-Error -LogPath $sLogFile -ErrorDesc "$($_.exception.message) at testing Orchestrator URL" -ExitGracefully $False
    }

    if ($redisHost) {
        $LBkey = @("LoadBalancer.Enabled" , "LoadBalancer.UseRedis", "LoadBalancer.Redis.ConnectionString", "NuGet.Packages.ApiKey", "NuGet.Activities.ApiKey")

        $LBvalue = @("true", "true", "$($redisHost)", "$($getEncryptionKey.nugetKey)", "$($getEncryptionKey.nugetKey)")

        for ($i = 0; $i -lt $LBkey.count; $i++) {

            Set-AppSettings -path "C:\UiPathOrchestrator" -key $LBkey[$i] -value $LBvalue[$i]

        }

        SetMachineKey -webconfigPath "C:\UiPathOrchestrator\web.config" -validationKey $getEncryptionKey.Validationkey -decryptionKey $getEncryptionKey.DecryptionKey -validation "SHA1" -decryption "AES"

        Restart-WebSitesSite -Name "UiPath*"

    }

    #set storage path
    if ($orchestratorVersion -lt "19.4.1") {

        $LBkey = @("NuGet.Packages.Path", "NuGet.Activities.Path" )

        $LBvalue = @("\\$($nuGetStoragePath)", "\\$($nuGetStoragePath)\Activities")

        for ($i = 0; $i -lt $LBkey.count; $i++) {

            Set-AppSettings -path "C:\UiPathOrchestrator" -key $LBkey[$i] -value $LBvalue[$i]

        }

    }
    else {
        $LBkey = "Storage.Location"
        $LBvalue = "RootPath=\\$($nuGetStoragePath)"
        Set-AppSettings -path "C:\UiPathOrchestrator" -key $LBkey -value $LBvalue
    }


    # Remove temp directory
    Log-Write -LogPath $sLogFile -LineValue "Removing temp directory $($tempDirectory)"
    Remove-Item $tempDirectory -Recurse -Force | Out-Null


    #Set Deployment Key
    #Login to Orchestrator via API
    $dataLogin = @{
        tenancyName            = $tennant
        usernameOrEmailAddress = $orchestratorAdminUsername
        password               = $orchestratorAdminPassword
    } | ConvertTo-Json

    $orchUrl_login = "localhost/account/login"

    #Get the login session used for all requests
    $orchWebResponse = Invoke-RestMethod -Uri $orchUrl_login  -Method Post -Body $dataLogin -ContentType "application/json" -UseBasicParsing -Session websession

    #Get Orchestrator Deployment Keys & Settings
    $getNugetKey = 'localhost/odata/Settings'
    $getNugetKeyResponse = Invoke-RestMethod -Uri $getNugetKey -Method GET -ContentType "application/json" -UseBasicParsing -WebSession $websession

    $nugetNameKeys = @("NuGet.Packages.ApiKey", "NuGet.Activities.ApiKey")
    $nugetValueKey = $($getEncryptionKey.nugetKey)

    foreach ($nugetNameKey in $nugetNameKeys) {

        $getOldNugetKey = $getNugetKeyResponse.value | Where-Object { $_.Name -eq $nugetNameKey } | Select-Object -ExpandProperty value

        $insertNugetPackagesKey = @{
            Value = $nugetValueKey
            Name  = $nugetNameKey
        } | ConvertTo-Json

        if ($getOldNugetKey -ne $nugetValueKey) {

            $orchUrlSettings = "localhost/odata/Settings('$nugetNameKey')"
            $orchWebSettingsResponse = Invoke-RestMethod -Method PUT -Uri $orchUrlSettings -Body $insertNugetPackagesKey -ContentType "application/json" -UseBasicParsing -WebSession $websession

        }
    }

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
      Generate web.config keys.

    .Description
      Generate same AppEncryption key, Nuget API keys, Machine Validation and Decryption keys based on a passphrase.

    .PARAMETER passphrase
      String. Mandatory. Passphrase to generate AppEncryption key, Nuget API keys, Machine Validation and Decryption keys. Example: $passphrase = "YourP@ssphr4s3!"

    .INPUTS
      Parameters above.

    .OUTPUTS
      Encyption key, Nuget API key, Machine Validation and Decryption keys.
    
    .Example
      Generate-Key -passphrase "YourP@ssphr4s3!"
#>
function Generate-Key {

    param(

        [Parameter(Mandatory = $true)]
        [string]
        $passphrase
    
    )
    function KeyGenFromBuffer([int] $KeyLength, [byte[]] $Buffer) {

        (1..$KeyLength | ForEach-Object { '{0:X2}' -f $Buffer[$_] }) -join ''

    }

    # Register CryptoProviders
    $hashProvider = New-Object System.Security.Cryptography.SHA256CryptoServiceProvider
    $encrypter = New-Object System.Security.Cryptography.AesCryptoServiceProvider

    $encrypter.Key = $hashProvider.ComputeHash([System.Text.ASCIIEncoding]::UTF8.GetBytes($passphrase))

    $encryptionKey = [System.Convert]::ToBase64String($encrypter.Key)

    # NugetKey from passphrase
    $nugethashProvider = New-Object System.Security.Cryptography.MD5CryptoServiceProvider

    $nugetGUID = $nugethashProvider.ComputeHash([System.Text.ASCIIEncoding]::UTF8.GetBytes($passphrase))

    $nugetkey = [System.guid]::New($nugetGUID)

    $BufferKeyPrimary = [system.Text.Encoding]::UTF8.GetBytes($encrypter.Key)
    $BufferKeySecondary = [system.Text.Encoding]::UTF8.GetBytes($BufferKeyPrimary)

    $decryptionKey = KeyGenFromBuffer -Buffer $BufferKeyPrimary -KeyLength 32

    $validationKey = KeyGenFromBuffer -Buffer $BufferKeySecondary -KeyLength 64

    $hashProvider.Dispose()
    $encrypter.Dispose()

    New-Object -TypeName PSObject -Property @{
        Validationkey = $validationkey
        DecryptionKey = $decryptionKey
        encryptionKey = $encryptionKey
        nugetKey      = $nugetkey.Guid
    }

}

<#
    .SYNOPSIS
      Modify MachineKey.

    .Description
      Modify MachineKey section in an existing web.config.

    .PARAMETER webconfigPath
      Mandatory. String. Path of an existing web.config. Example: $webconfigPath = "C:\UiPathOrchestrator\web.config"

    .PARAMETER validationKey
      Mandatory. String. The key name to be added/modified . Example: $validationKey = "ValidationKey 128 bytes"

    .PARAMETER decryptionKey
      Mandatory. String. The value to be added/modified for the specified key. Example: $decryptionKey = "DecryptionKey 64 bytes"

    .PARAMETER validation
      Mandatory. String. The value to be added/modified for the specified key. Example: $validation = "SHA1"

    .PARAMETER decryption
      Mandatory. String. The value to be added/modified for the specified key. Example: $decryption = "AES"

    .INPUTS
      Parameters above.

    .OUTPUTS
      None
    
    .Example
      SetMachineKey -webconfigPath "C:\UiPathOrchestrator\web.config" -validationKey "ValidationKey 128 bytes" -decryptionKey "DecryptionKey 64 bytes" -validation "SHA1" -decryption "AES"

#>
function SetMachineKey {

    param(

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $webconfigPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $validationKey,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $decryptionKey,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $validation,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $decryption

    )

    $currentDate = (get-date).tostring("mm_dd_yyyy-hh_mm_s") # month_day_year - hours_mins_seconds

    $machineConfig = $webconfigPath

    if (Test-Path $machineConfig) {
        $xml = [xml](get-content $machineConfig)
        $xml.Save($machineConfig + "_$currentDate")
        $root = $xml.get_DocumentElement()
        $system_web = $root."system.web"
        if ($system_web.machineKey -eq $nul) {
            $machineKey = $xml.CreateElement("machineKey")
            $a = $system_web.AppendChild($machineKey)
        }
        $system_web.SelectSingleNode("machineKey").SetAttribute("validationKey", "$validationKey")
        $system_web.SelectSingleNode("machineKey").SetAttribute("decryptionKey", "$decryptionKey")
        $system_web.SelectSingleNode("machineKey").SetAttribute("validation", "$validation")
        $system_web.SelectSingleNode("machineKey").SetAttribute("decryption", "$decryption")
        $a = $xml.Save($machineConfig)
    }
    else { 
        Write-Error -Message "Error: Webconfig does not exist in '$webconfigPath'"
        Log-Error -LogPath $sLogFile -ErrorDesc "Error: Webconfig does not exist '$webconfigPath'" -ExitGracefully $True
    }
}

<#
    .SYNOPSIS
      Add/Modify AppSettings.

    .Description
      Add/Modify AppSettings section in an existing web.config.

    .PARAMETER path
      Mandatory. String. Path of an existing web.config. Example: $path = "C:\UiPathOrchestrator"

    .PARAMETER key
      Mandatory. String. The key name to be added/modified . Example: $key = "NuGet.Packages.Path"

    .PARAMETER value
      Mandatory. String. The value to be added/modified for the specified key. Example: $value = "\\localhost\NugetPackagesFolder"

    .INPUTS
      Parameters above.

    .OUTPUTS
      None
    
    .Example
      Set-AppSettings -path "C:\UiPathOrchestrator" -key "NuGet.Packages.Path" -value "\\localhost\NugetPackagesFolder"
#>
function Set-AppSettings {
    param (
        # web.config path
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $path,

        # Key to add/update
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $key,

        # Value
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $value
    )


    # Make a backup copy before editing
    $ConfigBackup = "$path\web.config.$(Get-Date -Format yyyyMMdd_hhmmsstt).backup"
    try { Copy-Item -Path "$path\web.config" -Destination $ConfigBackup -Force -EA 1 } catch { throw }
    Write-Verbose "Backed up '$path\web.config' to '$ConfigBackup'"
    Log-Write -LogPath $sLogFile -LineValue "Backed up '$path\web.config' to '$ConfigBackup'"


    $webconfig = Join-Path $path "web.config"
    [bool] $found = $false

    if (Test-Path $webconfig) {
        $xml = [xml](get-content $webconfig);
        $root = $xml.get_DocumentElement();

        foreach ($item in $root.appSettings.add) {
            if ($item.key -eq $key) {
                $item.value = $value;
                $found = $true;
            }
        }

        if (-not $found) {
            $newElement = $xml.CreateElement("add");
            $nameAtt1 = $xml.CreateAttribute("key")
            $nameAtt1.psbase.value = $key;
            $newElement.SetAttributeNode($nameAtt1);

            $nameAtt2 = $xml.CreateAttribute("value");
            $nameAtt2.psbase.value = $value;
            $newElement.SetAttributeNode($nameAtt2);

            $xml.configuration["appSettings"].AppendChild($newElement);
        }

        $xml.Save($webconfig)
    }
    else {
        Write-Error -Message "Error: File not found '$webconfig'"
        Log-Error -LogPath $sLogFile -ErrorDesc "Error: File not found '$webconfig'" -ExitGracefully $True
    }
}

<#
    .SYNOPSIS
      Test URL.

    .Description
      Test if the installation of the UiPath Orchestrator it's successfully via URL.

    .PARAMETER orchestratorURL
      String. URL of the recently deployed orchestrator. Example: $orchestratorURL = https://localhost

    .INPUTS
      Parameters above.

    .OUTPUTS
      None
    
    .Example
      TestOrchestratorConnection -orchestratorURL "https://$hostname"
#>
function TestOrchestratorConnection {
    param (
        [string]
        $orchestratorURL
    )
    # First we create the request.
    $HTTP_Request = [System.Net.WebRequest]::Create("$orchestratorURL")

    # We then get a response from the site.
    $HTTP_Response = $HTTP_Request.GetResponse()

    # We then get the HTTP code as an integer.
    $HTTP_Status = [int]$HTTP_Response.StatusCode

    if ($HTTP_Status -eq 200) {
        Log-Write -LogPath $sLogFile -LineValue "Orchestrator Site is OK!"
    }
    else {
        Log-Write -LogPath $sLogFile -LineValue "The Orchestrator Site may be down, please check!"
    }

    # Finally, we clean up the http request by closing it.
    $HTTP_Response.Close()

}

<#
    .SYNOPSIS
      Install Windows Features.

    .Description
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
            Enable-WindowsOptionalFeature -Online -FeatureName $feature -all -NoRestart
        }
        catch {
            Log-Error -LogPath $sLogFile -ErrorDesc "$($_.exception.message) on installing $($feature)" -ExitGracefully $True
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
        if ((Test-Path -Path $sFullPath)) {
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
        if ($ExitGracefully -eq $True) {
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
        if (!($NoExit) -or ($NoExit -eq $False)) {
            Exit
        }
    }
}


Log-Start -LogPath $sLogPath -LogName $sLogName -ScriptVersion $sScriptVersion
Main
Log-Finish -LogPath $sLogFile
