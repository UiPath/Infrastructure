[CmdletBinding()]

param(
    [Parameter(Mandatory = $true)]
    [string]  $databaseServerName,

    [Parameter(Mandatory = $true)]
    [string]  $databaseName,

    [Parameter(Mandatory = $true)]
    [string]  $databaseUserName,

    [Parameter(Mandatory = $true)]
    [string]  $databasePassword,

    [Parameter(Mandatory = $true)]
    [string] $orchestratorTenantName,

    [Parameter(Mandatory = $true)]
    [string] $orchestratorAdminPassword,

    [Parameter(Mandatory=$false)]
    [ValidateScript( { if (($_ -as [System.URI]).AbsoluteURI -eq $null) { throw "Invalid" } return $true })]
    [string] $orchestratorUrl,

    [Parameter(Mandatory=$false)]
    [ValidateScript( { if (($_ -as [System.URI]).AbsoluteURI -eq $null) { throw "Invalid" } return $true })]
    [string] $identityServerUrl,

    [Parameter(Mandatory = $true)]
    [string] $identityInstallationToken,

    [Parameter()]
    [ValidateScript( { if (($_ -as [System.URI]).AbsoluteURI -eq $null) { throw "Invalid" } return $true })]
    [string] $publicUrl
)

$ErrorActionPreference = "Stop"
[System.String]$rootDirectory = "C:\cfn"
[System.String]$installLog = Join-Path -Path $script:rootDirectory -ChildPath "log\install.log"
[System.String]$testManagerHost = ([System.URI]$publicUrl).Host


function Restart-TestManagerSite {
param(
        [string] $siteName = "UiPathTestManager"
)

    try {
        Write-Host "Adding new binding and restarting $siteName"
        New-WebBinding -Name $siteName -IPAddress "*" -Port 443 -Protocol "https"
        Stop-Website -Name $siteName
        Start-Website -Name $siteName
    }
    catch {
        Write-Error -Exception $_.Exception -Message "Failed to configure Orchestrator"
        throw $_.Exception
    }
}


function Get-TestManagerMsiProperties {

    $msiProperties += @{
        "DB_SERVER_NAME" = "$databaseServerName";
        "DB_DATABASE_NAME" = "$databaseName";
        "DB_USER_NAME" = "$databaseUserName";
        "DB_USER_PASSWORD" = "$databasePassword";
        "DB_AUTHENTICATION_MODE" = "ServerAuthentication";
    }

    $msiProperties += @{
        "ORCHESTRATOR_TENANT_NAME" = "$orchestratorTenantName";
        "ORCHESTRATOR_ADMIN_PASSWORD" = "$orchestratorAdminPassword";
        "IDENTITY_INSTALLATION_TOKEN" = "$identityInstallationToken";
    }

    $msiProperties += @{
        "APPPOOL_IDENTITY_TYPE" = "ApplicationPoolIdentity";
    }

    $msiProperties += @{
        "CERTIFICATE_SUBJECT"    = $testManagerHost
    }

    $msiProperties += @{
        "ORCHESTRATOR_URL" = "$orchestratorUrl";
        "IDENTITY_URL" = "$identityServerUrl";
        "TEST_MANAGER_URL" = "$publicUrl";
    }

    return $msiProperties
}


function Install-TestManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $msiPath,

        [Parameter(Mandatory = $true)]
        [string] $logPath,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $msiProperties
    )

    Write-Host "Installing UiPath"

    if (!(Test-Path $msiPath)) {
        throw "No .msi file found at path '$msiPath'"
    }

    $msiExecArgs = "/i `"$msiPath`" /q /l*vx `"$logPath`" "

    $msiExecArgs += (($msiProperties.GetEnumerator() | ForEach-Object { "$( $_.Key )=$( $_.Value )" }) -join " ")

    Write-Host "Installing Args: $msiExecArgs"

    $process = Start-Process "msiexec" -ArgumentList $msiExecArgs -Wait -PassThru

    Write-Host "Process exit code: $($process.ExitCode)"
}

function Remove-WebSite ($webSiteName, $port) {

    try {
        $WebSiteBindingExists = Get-WebBinding -Name "$webSiteName"
        if ($WebSiteBindingExists) {
            Stop-Website "$webSiteName"
            Set-ItemProperty "IIS:\Sites\$webSiteName" serverAutoStart False
            Remove-WebBinding -Name "$webSiteName" -BindingInformation "*:${port}:"
            Write-Host "Removed $webSiteName WebSite !"
        }
    }
    catch {
        Write-Error -Exception $_.Exception -Message "Failed to remove website $webSiteName"
        throw $_.Exception
    }
}

function Test-TestManagerInstallation {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript( { if (($_ -as [System.URI]).AbsoluteURI -eq $null) { throw "Invalid" } return $true })]
        [string]$Url
    )

    try {
        $ErrorActionPreference = "Stop"
        $tries = 20
        Write-Verbose "Trying to connect to TestManager at $Url"
        while ($tries -ge 1) {
            try {
                Invoke-WebRequest -URI $Url'/api/health/ready' -Method 'GET' -TimeoutSec 180 -UseBasicParsing
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

function Main {
    . "$PSScriptRoot\Install-SelfSignedCertificate.ps1" -rootPath "$rootDirectory" -certificatePassword $orchestratorAdminPassword -orchestratorHost $testManagerHost

    $msiProperties = Get-TestManagerMsiProperties
    Install-TestManager -msiPath "$rootDirectory\sources\UiPathTestManager.msi" -logPath $script:installLog -msiProperties $msiProperties

    Remove-WebSite -webSiteName "Default Web Site" -port "80"

    Restart-TestManagerSite
    Test-TestManagerInstallation -Url $publicUrl -Verbose
}


try {
    Main
}
catch {
    Write-Host "Failed to install Test Manager: $($_.Exception)"
    throw $_.Exception
}
