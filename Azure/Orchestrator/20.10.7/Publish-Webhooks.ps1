param(
    [ValidateScript( { if (-Not ($_ | Test-Path -PathType Leaf)) { throw "The webhooks package file path parameter ( -package ) is not valid." } return $true })]
    [Parameter(Mandatory = $true)]
    [string] $package,
	
    [ValidateSet("Deploy", "Update")]
    [string] $action = "Deploy",

    [Parameter(Mandatory = $false)]
    [string] $azureAccountApplicationId,

    [Parameter(Mandatory = $false)]
    [string] $azureAccountPassword,

    [Parameter(Mandatory = $false)]
    [string] $azureSubscriptionId,

    [Parameter(Mandatory = $false)]
    [string] $azureAccountTenantId,

    [Parameter(Mandatory = $true)]
    [string] $resourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $appServiceName,
    
    [switch] $azureUSGovernmentLogin,
    
    [string] $productionSlotName = "Production",
	
    [switch] $stopApplicationBeforePublish,

    [switch] $noAzureAuthentication
)

Add-PSSnapin WDeploySnapin3.0

Import-Module ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".\ps_utils\ZipUtils.ps1"            ))) -Force
Import-Module ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".\ps_utils\MiscUtils.ps1"           ))) -Force
Import-Module ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".\ps_utils\MsDeployUtils.ps1"       ))) -Force
Import-Module ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".\ps_utils\AzureDeployUtils.ps1"    ))) -Force

function Main {

    # set script constants
    if (!$noAzureAuthentication) {
        $script:azureDetails = @{
            azureAccountPassword      = $azureAccountPassword;
            azureAccountApplicationId = $azureAccountApplicationId;
            azureSubscriptionId       = $azureSubscriptionId;
            azureAccountTenantId      = $azureAccountTenantId;
            azureUSGovernmentLogin     = $azureUSGovernmentLogin;
        }
    }

    $script:appServiceDetails = @{
        targetSlot        = if ($deploymentSlotName) { $deploymentSlotName } else { $productionSlotName };
        appServiceName    = $appServiceName
        resourceGroupName = $resourceGroupName;
    }

    $script:tempDirectory = Join-Path ([System.IO.Path]::GetTempPath()) "azuredeploy-$(Get-Date -f "yyyyMMddhhmmssfff")"
    $script:publishSettingsPath = Join-Path $script:tempDirectory "$appServiceName.PublishSettings"

    # connect to Azure RM
    if (!$noAzureAuthentication) {
    Ensure-AzureRm
	
    AuthenticateToAzure @script:azureDetails
    }
    
    # read settings
    $publishSettings = Get-PublishSettings


    if ($stopApplicationBeforePublish) {
        Stop-WebApplication @script:appServiceDetails
    }
	
    # deploy package
    Deploy-Package $package $publishSettings
	
    if ($stopApplicationBeforePublish) {
        Start-WebApplication @script:appServiceDetails
    }
}

function Deploy-Package($package, $publishSettings) {
    $wdParameters = Get-WDParameters

    try {
        Write-Host "`nDeploying package $package on website $($publishSettings.SiteName)" -ForegroundColor Yellow

        Write-Host "`nWeb Deploy parameters:" -ForegroundColor Yellow
        Write-Host ($wdParameters | Out-String)

        $args = Build-MsDeployArgs `
            -parameters $wdParameters `
            -publishSettings $publishSettings

        Write-Host "`nExecuting command:`n" -ForegroundColor Yellow
        Write-Host "msdeploy.exe $args`n"

        $proccess = Start-MsDeployProcess $args

        if ($proccess.ExitCode) {
            Write-Error "`nFailed to deploy package $package"
            Exit 1
        }

        Write-Host "`nPackage $package deployed successfully" -ForegroundColor Green        
    }
    catch {
        DisplayException $_.Exception
        Exit 1
    }
}

function Get-PublishSettings {
        
    New-Item -ItemType Directory -Path $script:tempDirectory | Out-Null
    Download-PublishProfile @script:appServiceDetails -outputPath $script:publishSettingsPath

    if ($script:publishSettingsPath -and (Test-Path $script:publishSettingsPath)) {
        return Get-WDPublishSettings -FileName $script:publishSettingsPath
    }
    else {
        Write-Error "No publishSettings file found at '$($script:publishSettingsPath)'"
        Exit 1
    }
}

function DisplayException($ex) {
    Write-Host $ex | Format-List -Force
}

function Get-WDParameters {
    return @{ }
}


Main