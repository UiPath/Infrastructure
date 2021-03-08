param(
    [ValidateScript({ if (-Not ($_ | Test-Path -PathType Leaf)) {throw "The DataMigrator file path parameter ( -cliPackage ) is not valid."} return $true })]
    [Parameter(Mandatory = $true, HelpMessage="Path to cli migrator .zip")]
    [string] $cliPackage,

    [ValidateScript({foreach ($key in @("azureAccountApplicationId", "azureAccountPassword", "azureSubscriptionId", "azureAccountTenantId") ) { if (-Not $_.ContainsKey($key)) { throw "Should contain key '$key'." }} return $true })]
    [Parameter(Mandatory=$false, HelpMessage="HashTable containing the following string properties { azureAccountApplicationId, azureAccountPassword, azureSubscriptionId, azureAccountTenantId }")]
    [System.Collections.Hashtable] $azureDetails, # { azureAccountApplicationId, azureAccountPassword, azureSubscriptionId, azureAccountTenantId }
    
    [ValidateScript({foreach ($key in @("resourceGroupName", "appServiceName", "targetSlot") ) { if (-Not $_.ContainsKey($key)) { throw "Should contain key '$key'." }} return $true })]
    [Parameter(Mandatory=$true, HelpMessage="HashTable containing the following string properties { resourceGroupName, appServiceName, targetSlot }")]
    [System.Collections.Hashtable] $orchDetails,  # { resourceGroupName, appServiceName, targetSlot }

    [ValidateScript({foreach ($key in @("resourceGroupName", "appServiceName", "targetSlot") ) { if (-Not $_.ContainsKey($key)) { throw "Should contain key '$key'." }} return $true })]
    [Parameter(Mandatory=$true, HelpMessage="HashTable containing the following string properties { resourceGroupName, appServiceName, targetSlot }")]
    [System.Collections.Hashtable] $webhookDetails,  # { resourceGroupName, appServiceName, targetSlot }

    [switch] $azureUSGovernmentLogin,

    [switch] $noAzureAuthentication
)

Add-PSSnapin WDeploySnapin3.0

Import-Module ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".\ps_utils\ZipUtils.ps1"            ))) -Force
Import-Module ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".\ps_utils\MiscUtils.ps1"           ))) -Force
Import-Module ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".\ps_utils\MsDeployUtils.ps1"       ))) -Force
Import-Module ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".\ps_utils\AzureDeployUtils.ps1"    ))) -Force
Import-Module ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".\ps_utils\WebhooksDeployUtils.ps1" ))) -Force

function Main {
    if (!$noAzureAuthentication) {
    # connect to Azure RM
    Ensure-AzureRm

    $script:azureDetails.azureUSGovernmentLogin = $azureUSGovernmentLogin

    AuthenticateToAzure @script:azureDetails
    }

    Set-ScriptConstants

    # extract migration tool
    Init-TempFolder $script:tempDirectory $cliPackage

    # read deployment settings for Webhooks and Orchestrator
    $orchPublishSettings     = Read-PublishSettings $script:orchPublishSettingsPath
    $orchFtpPublishSettings  = Get-FtpPublishProfile $orchPublishSettingsPath

    try
    {
        Download-WebsiteFile "/Web.config" $script:orchWebConfigPath $orchFtpPublishSettings
    }
    catch
    {
        Write-Error $_.Exception.Message
        exit 1
    }

    # run migration tool and create appsettings.production.json
    Run-SettingsMigrator `
        -orchWebConfigPath $script:orchWebConfigPath `
        -webhooksAppSettingPath $script:webhooksAppSettingPath

    # upload appsettings file with overriden settings
    $webhookFtpPublishProfile = Get-FtpPublishProfile $script:webhooksPublishSettingsPath
    Upload-WebsiteFile -websiteFilePath $script:appSettingsName -localFilePath $script:webhooksAppSettingPath -publishProfile $webhookFtpPublishProfile

    # set Webhook Service app settings variables for Orchestrator and Ledger clients
    $newSettings = @{
        "LedgerConfiguration:Subscribers:0:ConnectionString"    = $orchPublishSettings.SqlDBConnectionString;
        "OrchestratorSqlClientSettings:ConnectionString"        = $orchPublishSettings.SqlDBConnectionString;
    }    
    Update-WebSiteSettings -siteDetails $webhookDetails -newSettings $newSettings

    # set Orchestrator app settings variables for Ledger integration
    $newSettings = @{
        "Webhooks.LedgerIntegration.Enabled" = "true";
    }
    Update-WebSiteSettings -siteDetails $orchDetails -newSettings $newSettings

    # restart WH App
    Stop-WebApplication @webhookDetails
    Start-WebApplication @webhookDetails

    # cleanup temporary data
    Remove-TempFolder
}

function Set-ScriptConstants {

    $script:appSettingsName = "appsettings.azure.json" #default value for ASPNETCORE_ENVIRONMENT in Azure is ... 'Azure'
    $script:tempDirectory = Join-Path ([System.IO.Path]::GetTempPath()) "azuredeploy-$(Get-Date -f "yyyyMMddhhmmssfff")"
    New-Item -ItemType Directory -Path $script:tempDirectory | Out-Null

    $script:webhooksPublishSettingsPath = Join-Path $script:tempDirectory "$($webhookDetails.appServiceName).PublishSettings"
    $script:orchPublishSettingsPath     = Join-Path $script:tempDirectory "$($orchDetails.appServiceName).PublishSettings"
    $script:orchWebConfigPath           = Join-Path $script:tempDirectory "orchestrator.web.config";
    $script:webhooksAppSettingPath      = Join-Path $script:tempDirectory $script:appSettingsName;

    Download-PublishProfile @script:webhookDetails -outputPath $script:webhooksPublishSettingsPath
    Download-PublishProfile @script:orchDetails    -outputPath $script:orchPublishSettingsPath
}

Main