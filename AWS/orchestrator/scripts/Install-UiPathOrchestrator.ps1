<#
    .SYNOPSIS
      Install UiPath Orchestrator.

    .Description
      Install UiPath Orchestrator and configure UiPath.Orchestrator.dll.config

    .PARAMETER orchestratorFolder
      String. Path where Orchestrator will be installed. Example: $orchestratorFolder = "C:\Program Files(x86)\UiPath\Orchestrator"

    .PARAMETER databaseServerName
      String. Mandatory. SQL server name. Example: $databaseServerName = "SQLServerName.local"

    .PARAMETER databaseName
      String. Mandatory. Database Name. Example: $databaseName = "devtestdb"

    .PARAMETER databaseUserName
      String. Mandatory. Database Username. Example: $databaseUserName = "devtestdbuser"

    .PARAMETER databaseUserPassword
      String. Mandatory. Database Password  Example: $databaseUserPassword = "d3vt3std@taB@s3!"

    .PARAMETER redisServerHost
      String. There is no need to use Redis if there is only one Orchestrator instance. Redis is mandatory in multi-node deployment.  Example: $redisServerHost = "redishostDNS"

    .PARAMETER nuGetStoragePath
      String. Mandatory. Storage Path where the Nuget Packages are saved. Also you can use NFS or SMB share.  Example: $nuGetStoragePath = "\\nfs-share\NugetPackages"

    .PARAMETER orchestratorAdminPassword
      String. Mandatory. Orchestrator Admin password is necessary for a new installation and to change the Nuget API keys. Example: $orchestratorAdminPassword = "P@ssW05D!"

    .PARAMETER orchestratorAdminUsername
      String. Orchestrator Admin username in order to change the Nuget API Keys.  Example: $orchestratorAdminUsername = "admin"

    .INPUTS
      Parameters above.

    .OUTPUTS
      None

    .Example
      powershell.exe -ExecutionPolicy Bypass -File "\\fileLocation\Install-UiPathOrchestrator.ps1" -databaseServerName  "SQLServerName.local"  -databaseName "devtestdb"  -databaseUserName "devtestdbuser" -databaseUserPassword "d3vt3std@taB@s3!" -orchestratorAdminPassword "P@ssW05D!" -redisServerHost "redishostDNS" -NuGetStoragePath "\\nfs-share\NugetPackages"
#>
[CmdletBinding()]

param(

    [Parameter()]
    [ValidateSet('OrchestratorFeature, IdentityFeature')]
    [Array] $msiFeatures = ('OrchestratorFeature', 'IdentityFeature'),

    [Parameter(Mandatory = $true)]
    [string]  $databaseServerName,

    [Parameter(Mandatory = $true)]
    [string]  $databaseName,

    [Parameter(Mandatory = $true)]
    [string]  $databaseUserName,

    [Parameter(Mandatory = $true)]
    [string]  $databaseUserPassword,

    [Parameter()]
    [string[]] $redisServerHost,

    [Parameter()]
    [string] $redisServerPort,

    [Parameter()]
    [string] $redisServerPassword,

    [Parameter(Mandatory = $true)]
    [string] $nuGetStoragePath,

    [Parameter()]
    [string] $orchestratorAdminUsername = "admin",

    [Parameter(Mandatory = $true)]
    [string] $orchestratorAdminPassword,

    [Parameter(Mandatory=$false)]
    [AllowEmptyString()]
    [string] $orchestratorLicenseCode,

    [Parameter()]
    [string] $configTableName,

    [Parameter()]
    [string] $configS3BucketName,

    [Parameter()]
    [ValidateScript( { if (($_ -as [System.URI]).AbsoluteURI -eq $null) { throw "Invalid" } return $true })]
    [string] $publicUrl


)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ErrorActionPreference = "Stop"
[System.String]$rootDirectory = "C:\cfn"
[System.String]$installLog = Join-Path -Path $script:rootDirectory -ChildPath "log\install.log"
[System.String]$orchestratorHost = ([System.URI]$publicUrl).Host
[System.String]$orchestratorTenant = "host"

function Main {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    RemoveIISDirectoryBrowsingFeature

    $msiProperties = Get-OrchestratorMsiProperties

    Install-UiPathOrchestratorEnterprise -msiPath "$rootDirectory\sources\UiPathOrchestrator.msi" -logPath $script:installLog -msiFeatures $msiFeatures -msiProperties $msiProperties

    Remove-WebSite -webSiteName "Default Web Site" -port "80"
}

function RemoveIISDirectoryBrowsingFeature {
    try {
        $checkFeature = Get-WindowsFeature "IIS-DirectoryBrowsing"
        if ($checkFeature.Installed -eq $true) {
            Disable-WindowsOptionalFeature -FeatureName IIS-DirectoryBrowsing -Remove -NoRestart -Online
            Write-Verbose "Feature IIS-DirectoryBrowsing is removed"
        }
    }
    catch {
        Write-Error -Exception $_.Exception -Message "Failed to remove feature IIS-DirectoryBrowsing"
        throw $_.Exception
    }
}

function Restart-OrchestratorSite {
param(
        [string] $siteName = "UiPath Orchestrator"
)

    try {
        New-WebBinding -Name $siteName -IPAddress "*" -Port 443 -Protocol "https"
        Stop-Website -Name $siteName
        Start-Website -Name $siteName
        Write-Verbose "Adding new binding and restarting Orchestrator WebSite !"
    }
    catch {
        Write-Error -Exception $_.Exception -Message "Failed to configure Orchestrator"
        throw $_.Exception
    }
}


function Get-OrchestratorMsiProperties {
    if (Test-Path "$rootDirectory\config.json") {
        $msiProperties = @{
            "PARAMETERS_FILE" = "$rootDirectory\config.json"
            "SECONDARY_NODE"  = "1"
            "WEBSITE_HOST"    = $orchestratorHost
        }
    }
    else {
        $msiProperties += @{
            "DB_SERVER_NAME"              = "$databaseServerName";
            "DB_DATABASE_NAME"            = "$databaseName";
            "HOSTADMIN_PASSWORD"          = "$orchestratorAdminPassword";
            "DEFAULTTENANTADMIN_PASSWORD" = "$orchestratorAdminPassword";
            "TELEMETRY_ENABLED"           = "1";
        }

        $msiProperties += @{ "APPPOOL_IDENTITY_TYPE" = "APPPOOLIDENTITY"; }

        $msiProperties += @{
            "DB_AUTHENTICATION_MODE" = "SQL";
            "DB_USER_NAME"           = "$databaseUserName";
            "DB_PASSWORD"            = "$databaseUserPassword";
        }

        $msiProperties += @{
            "CERTIFICATE_SUBJECT"    = $orchestratorHost
            "IS_CERTIFICATE_SUBJECT" = $orchestratorHost
        }

        $msiProperties += @{
            "OUTPUT_PARAMETERS_FILE" = "$rootDirectory\config.json";
            "PUBLIC_URL"             = "$publicUrl"
            "WEBSITE_HOST"           = $orchestratorHost
        }

        $msiProperties += @{
            "REDIS_HOST"     = $redisServerHost -join ','
            "REDIS_PORT"     = $redisServerPort
            "REDIS_PASSWORD" = $redisServerPassword
        }

        $msiProperties += @{
            "STORAGE_TYPE"     = "FileSystem"
            "STORAGE_LOCATION" = "RootPath=\\$nuGetStoragePath"
        }
    }
    return $msiProperties
}

function Install-UiPathOrchestratorEnterprise {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $msiPath,
        [string] $logPath,
        [Parameter(Mandatory = $true)]
        [string[]] $msiFeatures,
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $msiProperties
    )

    Write-Verbose "Installing UiPath"

    if (!(Test-Path $msiPath)) {
        throw "No .msi file found at path '$msiPath'"
    }

    $msiExecArgs = "/i `"$msiPath`" /q /l*vx `"$logPath`" "

    $msiExecArgs += "ADDLOCAL=`"$( $msiFeatures -join ',' )`" "
    $msiExecArgs += (($msiProperties.GetEnumerator() | ForEach-Object { "$( $_.Key )=$( $_.Value )" }) -join " ")

    Write-Verbose "Installing Features: $msiFeatures"
    Write-Verbose "Installing Args: $msiExecArgs"

    $process = Start-Process "msiexec" -ArgumentList $msiExecArgs -Wait -PassThru

    Write-Verbose "Process exit code: $($process.ExitCode)"
}

function Remove-WebSite ($webSiteName, $port) {

    try {
        $WebSiteBindingExists = Get-WebBinding -Name "$webSiteName"
        if ($WebSiteBindingExists) {
            Stop-Website "$webSiteName"
            Set-ItemProperty "IIS:\Sites\$webSiteName" serverAutoStart False
            Remove-WebBinding -Name "$webSiteName" -BindingInformation "*:${port}:"
            Write-Verbose "Removed $webSiteName WebSite !"
        }
    }
    catch {
        Write-Error -Exception $_.Exception -Message "Failed to remove website $webSiteName"
        throw $_.Exception
    }
}

function Connect-ToOrchestrator {
    param (
        [Parameter(Mandatory = $true)]
        [string] $tenant,
        [Parameter(Mandatory = $true)]
        [string] $username,
        [Parameter(Mandatory = $true)]
        [string] $password
    )

    $tries = 20
    while ($tries -ge 1) {
        try {
            $orchLoginPath = "/api/account/authenticate"
            $dataLogin = @{
                tenancyName            = $tenant
                usernameOrEmailAddress = $username
                password               = $password
            } | ConvertTo-Json

            $orchLoginUri = [System.Uri]::new([System.Uri]$publicUrl, $orchLoginPath)
            $loginResponse = Invoke-RestMethod -Uri $orchLoginUri.AbsoluteUri  -Method Post -Body $dataLogin -ContentType "application/json"
            $bearerToken = $loginResponse.result
            return $bearerToken
        }
        catch {
            $tries--
            Write-Verbose "Exception: $_"
            if ($tries -lt 1) {
                throw "Site not started in due time. Failed to authenticate 20 times in a row"
            }
            else {
                Write-Verbose "Failed to authenticate to Orchestrator. Try number: $tries. Retrying again in 30 second"
                Start-Sleep 30
            }
        }
    }
}

function Set-OrchestratorLicense {
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $licenseCode,
        [Parameter(Mandatory = $true)]
        [string] $tenant,
        [Parameter(Mandatory = $true)]
        [string] $username,
        [Parameter(Mandatory = $true)]
        [string] $bearerToken
    )

    Try {

        if ($licenseCode) {

            $headers = @{Authorization = "Bearer $bearerToken"}

            $getLicensePath = "/odata/HostLicenses"
            $orchGetLicenseUri = [System.Uri]::new([System.Uri]$publicUrl, $getLicensePath)

            $getTenantLicense = Invoke-RestMethod -Uri $orchGetLicenseUri -Method GET -ContentType "application/json" -UseBasicParsing -Headers $Headers
            if ( $getTenantLicense.'@odata.count' -eq "0") {

                $activateLicensePath = "/odata/HostLicenses/UiPath.Server.Configuration.OData.ActivateLicenseOnline"
                $licenseBody = @{
                    licenseKey = $licenseCode
                    environment = $tenant
                    email= $username
                } | ConvertTo-Json
                $orchLicenseUri = [System.Uri]::new([System.Uri]$publicUrl, $activateLicensePath)

                Invoke-RestMethod -Uri $orchLicenseUri.AbsoluteUri  -Method Post -Body $licenseBody -ContentType "application/json" -Headers $Headers

                Write-Verbose "Licensing Orchestrator's $tenant tenant..."
            }

            Write-Verbose "Host tenant already licensed"
        }
        else{
            Write-Verbose "License code was not provided !"
        }
    }
    Catch {
        Write-Verbose "License activation failed. The following error occurred: $( $_.exception.message )"
    }

}

function Test-OrchestratorInstallation {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript( { if (($_ -as [System.URI]).AbsoluteURI -eq $null) { throw "Invalid" } return $true })]
        [string]$Url
    )

    try {
        $ErrorActionPreference = "Stop"
        $tries = 20
        Write-Verbose "Trying to connect to Orchestrator at $Url"
        while ($tries -ge 1) {
            try {
                Invoke-WebRequest -URI $Url -Method 'GET' -TimeoutSec 180 -UseBasicParsing
                break
            }
            catch {
                $tries--
                Write-Verbose "Exception: $_"
                if ($tries -lt 1) {
                    throw $_
                }
                else {
                    Write-Verbose "Failed to GET $Url. Retrying again in 10 seconds"
                    Start-Sleep 10
                }
            }
        }

    }
    catch {
        Write-Error -Exception $_.Exception -Message "Failed to connect to installed Orchestrator at $Url"
        throw $_.Exception
    }
}

. "$PSScriptRoot\Set-MutexLock.ps1" -Lock -TableName $configTableName -Verbose

try {
    . "$PSScriptRoot\Get-File.ps1" -Source "s3://$configS3BucketName/config.json" -Destination "$rootDirectory\config.json" -Verbose
    . "$PSScriptRoot\Get-File.ps1" -Source "s3://$configS3BucketName/$orchestratorHost.pfx" -Destination "$rootDirectory\$orchestratorHost.pfx" -Verbose
}
catch {
    Write-Verbose "No file was downloaded from s3://$configS3BucketName/config.json"
}

try {
    if ((Test-Path "$rootDirectory\config.json") -and (Test-Path "$rootDirectory\$orchestratorHost.pfx") ) {
        Write-Information "Configuration already exists, performing installation as secondary node"
        . "$PSScriptRoot\Set-MutexLock.ps1" -Release -TableName $configTableName -Verbose
        . "$PSScriptRoot\Install-SelfSignedCertificate.ps1" -rootPath "$rootDirectory" -certificatePassword $orchestratorAdminPassword -orchestratorHost $orchestratorHost
        Main
        Restart-OrchestratorSite
        $bearerToken = Connect-ToOrchestrator -tenant $orchestratorTenant -username $orchestratorAdminUsername -password $orchestratorAdminPassword
        Set-OrchestratorLicense -licenseCode $orchestratorLicenseCode -tenant $orchestratorTenant -username $orchestratorAdminUsername -bearerToken $bearerToken
    }
    else {
        Write-Verbose "No configuration is available, performing installation for the first time"
        . "$PSScriptRoot\Install-SelfSignedCertificate.ps1" -rootPath "$rootDirectory" -certificatePassword $orchestratorAdminPassword -orchestratorHost $orchestratorHost
        Main
        Write-Verbose "Performed installation for the first time, testing installation"
        Restart-OrchestratorSite
        Test-OrchestratorInstallation -Url $publicUrl -Verbose
        $bearerToken = Connect-ToOrchestrator -tenant $orchestratorTenant -username $orchestratorAdminUsername -password $orchestratorAdminPassword
        Set-OrchestratorLicense -licenseCode $orchestratorLicenseCode -tenant $orchestratorTenant -username $orchestratorAdminUsername -bearerToken $bearerToken
        Write-Verbose "Uploading the configuration"
        . "$PSScriptRoot\Write-ConfigToS3.ps1" -Source "$rootDirectory\config.json" -Destination "s3://$configS3BucketName/config.json"
        . "$PSScriptRoot\Write-ConfigToS3.ps1" -Source "$rootDirectory\$orchestratorHost.pfx" -Destination "s3://$configS3BucketName/$orchestratorHost.pfx"
        . "$PSScriptRoot\Set-MutexLock.ps1" -Release -TableName $configTableName -Verbose
    }
}
catch {
    Write-Verbose "Installation failed with $($_.Exception) , releasing mutex"
    . "$PSScriptRoot\Set-MutexLock.ps1" -Release -TableName $configTableName -Verbose
    Write-Error -Exception $_.Exception -Message "Failed to install Orchestrator"
    throw $_.Exception
}
