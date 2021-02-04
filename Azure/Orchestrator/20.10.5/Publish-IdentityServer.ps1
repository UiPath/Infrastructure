param(
    [ValidateScript({ if (-Not ($_ | Test-Path -PathType Leaf)) {throw "The IdentityServer file path parameter ( -package ) is not valid."} return $true })]
    [Parameter(Mandatory = $true)]
    [string] $package,

    [ValidateScript({ if (-Not ($_ | Test-Path -PathType Leaf)) {throw "The DataMigrator file path parameter ( -cliPackage ) is not valid."} return $true })]
    [Parameter(Mandatory = $true, HelpMessage="Path to cli migrator .zip")]
    [string] $cliPackage,

    [ValidateSet("Deploy", "Update")]
    [string] $action = "Deploy",

    [Parameter(Mandatory = $false)]
    [string] $azureAccountApplicationId,

    [Parameter(Mandatory = $false)]
    [string] $azureAccountPassword,

    [Parameter(Mandatory = $true)]
    [string] $azureSubscriptionId,

    [Parameter(Mandatory = $true)]
    [string] $azureAccountTenantId,

    [Parameter(Mandatory = $true)]
    [string] $resourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $appServiceName,
    
    [Parameter(Mandatory = $true)]
    [string] $orchestratorUrl, # public orchestrator url

    [string] $deploymentSlotName,

    [string] $productionSlotName = "Production",

    [System.Object] $appSettings,

    [string] $parametersOutputPath = "$PSScriptRoot\AzurePublishParameters.json",
    
    [string] $tmpDirectory,

    [switch] $stopApplicationBeforePublish,

    [switch] $azureUSGovernmentLogin,

    [switch] $unattended,

    [switch] $noAzureAuthentication
)

$ErrorActionPreference = "Stop"

# =========== Global variables declaration ===========
#         Declare script level variables here

$script:azureDetails        = $null # hash { azureAccountPassword, azureAccountApplicationId, azureSubscriptionId, azureAccountTenantId, azureUSGovernmentLogin }
$script:appServiceDetails   = $null # hash { targetSlot, fullAppServiceName, appServiceName, resourceGroupName }

$script:publishSettingsPath = $null # [string]
$script:tempDirectory       = $null # [string]

# ====================================================

Add-PSSnapin WDeploySnapin3.0
Import-Module ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".\ps_utils\ZipUtils.ps1"            ))) -Force
Import-Module ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".\ps_utils\MiscUtils.ps1"           ))) -Force
Import-Module ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".\ps_utils\MsDeployUtils.ps1"       ))) -Force
Import-Module ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".\ps_utils\AzureDeployUtils.ps1"    ))) -Force
Import-Module ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".\ps_utils\IdentityDeployUtils.ps1" ))) -Force

function Main {

    Set-ScriptConstants
    
    Check-InstalledAV
    Init-IdentityTempFolder $script:tempDirectory $cliPackage

    $publishSettings = Read-PublishSettings $script:publishSettingsPath

    if ($stopApplicationBeforePublish) {
        Stop-WebApplication @script:appServiceDetails
    }

    Deploy-Package $package $publishSettings

    Run-DbMigrator $publishSettings.SqlDBConnectionString

    if ($action -eq "Update")
    {
        Run-SeedMigrator `
            -identityConnectionString $publishSettings.SqlDBConnectionString `
            -orchestratorUrl $script:orchestratorUrl `
            -configFile $script:clientConfigFile
            
        Remove-ClientConfig $script:clientConfigFile
    }

    # set virtual path based on zip root folder
    $rootFolder = Get-ZipRootFolder $package
    Set-VirtualPath @script:appServiceDetails -virtualPath "/identity" -rootFolder $rootFolder

    # Set Orchestrator URL app setting
    $newSettings = @{
        "AppSettings__OrchestratorUrl" = $orchestratorUrl;
    }
    
    Update-WebSiteSettings -siteDetails $script:appServiceDetails -newSettings $newSettings

    if ($stopApplicationBeforePublish){
        Start-WebApplication @script:appServiceDetails
    }

    Remove-IdentityTempFolder
}

function Set-ScriptConstants {

    $script:azureDetails = @{
        azureAccountPassword      = $azureAccountPassword;
        azureAccountApplicationId = $azureAccountApplicationId;
        azureSubscriptionId       = $azureSubscriptionId;
        azureAccountTenantId      = $azureAccountTenantId;
        azureUSGovernmentLogin     = $azureUSGovernmentLogin;
    }

    $script:appServiceDetails = @{
        targetSlot         = if ($deploymentSlotName) { $deploymentSlotName } else { $productionSlotName };
        appServiceName     = $appServiceName
        resourceGroupName  = $resourceGroupName;
    }

    $script:clientConfigFile = "clients_config.json"

    Ensure-AzureRm

    if (!$noAzureAuthentication) { 
        AuthenticateToAzure @script:azureDetails
    }
    
    if (!$tmpDirectory)
    {
        $tmpDirectory = [System.IO.Path]::GetTempPath()
    }

    $script:tempDirectory = Join-Path $tmpDirectory "azuredeploy-$(Get-Date -f "yyyyMMddhhmmssfff")"
    New-Item -ItemType Directory -Path $script:tempDirectory | Out-Null

    $script:publishSettingsPath = Join-Path $script:tempDirectory "$appServiceName.PublishSettings"
    Download-PublishProfile @script:appServiceDetails -outputPath $script:publishSettingsPath
}


function Deploy-Package($package, $publishSettings) {

    if (($action -eq "Deploy") -and !$unattended) {

        Write-Warning "`n`nYou are running a fresh deployment.`nThis means that all settings will be generated and pushed to the target Service.`nPlease make sure that you are not deploying over an existing website, to avoid losing any settings.`nIf you are trying to update an existing website, please rerun the script with the -action parameter set to 'Update'.`n"

        if (!(Prompt-ForContinuation)) {
            Write-Output "`nExiting...`n"
            Exit 0
        }
    }

    $wdParameters = Get-WDParameters

    try {

        Write-Output "`nDeploying package $package on website $($publishSettings.SiteName)"

        Write-Output "`nWeb Deploy parameters:"
        Write-Output ($wdParameters | Out-String)

        $args = Build-MsDeployArgs `
            -parameters $wdParameters `
            -publishSettings $publishSettings

        Write-Output "`nExecuting command:`n"
        Write-Output "msdeploy.exe $args`n"

        $shouldContinue = $unattended -or (Prompt-ForContinuation)

        if (!$shouldContinue) {
            Write-Output "`nExiting...`n"
            Exit 0
        }

        Write-Output ""

        $proccess = Start-MsDeployProcess $args

        if ($proccess.ExitCode) {
          Write-Error "`nFailed to deploy package $package"
          Exit 1
        }

        Write-Output "`nPackage $package deployed successfully"
    } catch {
        DisplayException $_.Exception
        Exit 1
    }
}

function Get-WDParameters {
    # left for extensions purposes
    return @{ }
}


Main