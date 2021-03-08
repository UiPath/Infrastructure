param(
    [ValidateScript({ if (-Not ($_ | Test-Path -PathType Leaf)) {throw "The Orchestrator file path parameter ( -package ) is not valid."} return $true })]
    [Parameter(Mandatory = $true)]
    [string] $package,

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

    [string] $standbySlotName,

    [string] $productionSlotName = "Production",

    [System.Object] $appSettings,

    [string] $website,

    [string] $publishUrl,

    [string] $username,

    [string] $password,

    [string] $ftpPublishUrl,

    [string] $ftpUsername,

    [string] $ftpPassword,

    [string] $connectionString,

    [string] $testAutomationConnectionString,

    [string] $hostAdminPassword,

    [switch] $isHostPassOneTime,

    [string] $defaultTenantAdminPassword,

    [switch] $isDefaultTenantPassOneTime,

    [string] $redisConnectionString,

    [string] $loadBalancerUseRedis,

    [string] $robotsElasticSearchUrl,

    [string] $robotsElasticSearchUsername,

    [string] $robotsElasticSearchPassword,

    [string] $robotsElasticSearchTargets,

    [string] $serverElasticSearchUrl,

    [string] $serverElasticSearchIndex,

    [string] $serverDefaultTargets,

    [string] $serverElasticSearchDiagnosticsUsername,

    [string] $serverElasticSearchDiagnosticsPassword,

    [string] $storageType,

    [string] $storageLocation,

    [string] $packagesApiKey,

    [string] $activitiesApiKey,

    [switch] $useQuartzClustered,

    [string[]] $filesToSkip,

    [string[]] $foldersToSkip = @(
        "\\NuGetPackages",
        "\\NuGetPackages\\Activities",
        "\\Storage",
        "\\PackagesMigration"
    ),

    [string] $parametersOutputPath = "$PSScriptRoot\AzurePublishParameters.json",

    [switch] $stopApplicationBeforePublish,

    [ValidateScript({ if (-Not ($_ | Test-Path -PathType Leaf)) {throw "The Activities zip file path parameter ( -activitiesPackagePath ) is not valid."} return $true })]
    [string] $activitiesPackagePath,

    [ValidateScript({ if (-Not ($_ | Test-Path)) {throw "The Packages Migrator file path parameter ( -packageMigratorPath ) is not valid."} return $true })]
    [string] $packageMigratorPath,

    [string] $azureSignalRConnectionString,

    [switch] $testAutomationFeatureEnabled,

    [switch] $unattended,

    [switch] $azureUSGovernmentLogin,

    [System.Version] $azureRmVersion = "6.13.1",

    [bool] $autoSwap = $true,

    [string] $bucketsAvailableProviders,

    [string] $bucketsFileSystemAllowlist,

    [switch] $noAzureAuthentication
)

$ErrorActionPreference = "Stop"

Add-PSSnapin WDeploySnapin3.0

$azureRMModuleLocationBaseDir = 'C:\Modules\azurerm_6.7.0'
$azureRMModuleLocation = "$azureRMModuleLocationBaseDir\AzureRM\6.7.0\AzureRM.psd1"

function Import-AzureRmModuleFromLocalMachine  {

    if ((Get-Module AzureRM)) {
        Write-Host "Unloading AzureRM module ... "
        Remove-Module AzureRM
    }

    Write-Host "Importing module $azureRMModuleLocation"
    $env:PSModulePath = $azureRMModuleLocationBaseDir + ";" + $env:PSModulePath

    $currentVerbosityPreference = $Global:VerbosePreference

    $Global:VerbosePreference = 'SilentlyContinue'
    Import-Module $azureRMModuleLocation -Verbose:$false
    $Global:VerbosePreference = $currentVerbosityPreference
}

function Main {

    Set-ScriptConstants

    Validate-Parameters

    if ($stopApplicationBeforePublish) {
        StopWebApplication -slotName $deploymentSlotName
    }

    $publishSettings = Get-PublishSettings $script:publishSettingsPath

    if ($script:runPackageMigrator) {
        Write-Warning "`n`nPackages and activities will be migrated from FileSystem storage locations: '$script:packagesUrl'(packages), '$script:activitiesUrl'(activities) to storage type '$script:storageType', location $script:storageLocation."
        if (!$unattended) {

            if (!(Prompt-ForContinuation)) {
                Write-Host "`nExiting...`n" -ForegroundColor Yellow
                Exit 0
            }
        }

        Import-Module -Name '.\ps_utils\Migrate-Packages.psm1' -Force `
                      -ArgumentList $script:msDeployExe, $script:packageMigratorPath, $publishSettings.PublishSettings, $publishSettings.MigrationSettings.SQLDBConnectionString, $script:storageType, $script:storageLocation, $script:activitiesUrl, $script:packagesUrl, $script:instanceKey, $script:unattended
        Start-PackagesMigration
    }

    Deploy-Package $package $publishSettings.PublishSettings

    Update-AllDatabases $publishSettings

    if ($script:runPackageMigrator) {
        Finalize-PackagesMigration
        $appSettings = Add-Setting $appSettings "NuGet.Repository.Type" "Composite"
        $appSettings = Add-Setting $appSettings "InstanceKey" $script:instanceKey
    }

    Apply-AppSettings -deployAppSettings $appSettings -slotName $deploymentSlotName

    Invoke-ExtensionsValidation -configFilePath $script:newConfigPath

    if ($activitiesPackagePath) {
        Deploy-ActivitiesInCompositeMode $publishSettings
    }

    if ($stopApplicationBeforePublish){
         StartWebApplication -slotName $deploymentSlotName
    }

    if ($script:hotswap) {
        if (!$stopApplicationBeforePublish) {
            StartWebApplication -slotName $standbySlotName
        }
    }

    if($script:autoSwap) {
        if ($script:hotswap) {
            SwapSlots
            StopWebApplication -slotName $standbySlotName
        }
    }

    if ($script:appDomain) {
        [System.AppDomain]::Unload($script:appDomain)
    }

    Write-Host ""
    Write-Verbose "Removing temporary folder $($script:tempDirectory)"
    Remove-Item $script:tempDirectory -Recurse -Force
}

function Set-ScriptConstants {

    if (Test-Path 'C:\Modules\azurerm_6.7.0\AzureRM\6.7.0\AzureRM.psd1') {
        Import-AzureRmModuleFromLocalMachine
    } else {
        $azModules = (Get-Module AzureRM -ListAvailable -Verbose:$false | Where-Object {$_.Version.Major -ge $azureRmVersion.Major})
        if ($azModules) {
            Write-Host "AzureRM module version $($azureRmVersion.Major) or greater is already installed. Importing module ..."
        } else {
            Write-Host "AzureRM module version $azureRmVersion or later not found. Installing AzureRM $azureRmVersion" -ForegroundColor Yellow
            Install-Module AzureRM -RequiredVersion $azureRmVersion -Force -AllowClobber
        }
        Import-Module AzureRM -Verbose:$false
    }

    if (!$noAzureAuthentication) {
        AuthenticateToAzure
    }

    $script:aspNetConfigName = "Web.config"
    $script:aspNetCoreConfigName = "UiPath.Orchestrator.WebCore.Host.exe.config"
    $script:dotNetCoreConfigName = "UiPath.Orchestrator.dll.config"

    $script:msDeployExe = Join-Path ${env:ProgramFiles(x86)} "IIS\Microsoft Web Deploy V3\msdeploy.exe"

    $script:parametersOutputPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $script:parametersOutputPath ))
    $script:appSettingsOutputPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $script:appSettingsOutputPath ))

    $script:workingFolder = Get-Location
    $script:package = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($workingFolder, $script:package ))
    if ($script:packageMigratorPath) {
        $script:packageMigratorPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($workingFolder, $script:packageMigratorPath ))
    }

    $orchestratorPayloadTempDir = Join-Path $ENV:TEMP "OrchestratorMigration_$(Get-Date -Format 'yyyyMMddhhmmssfff')"

    Extract-FilesFromZip -zip $package -destinationFolder $orchestratorPayloadTempDir -filePattern "Content/*/bin/win-x64/publish/$script:dotNetCoreConfigName"
    if (Test-Path "$orchestratorPayloadTempDir/$script:dotNetCoreConfigName")
    {
        # We were able to find an AspNetCore configuration file in the package.
        $script:newConfigName = $script:dotNetCoreConfigName
        $script:webArchiveContentPath = "Content/*/bin/win-x64/publish/"
    }
    else
    {
        Extract-FilesFromZip -zip $package -destinationFolder $orchestratorPayloadTempDir -filePattern "Content/*/obj/Release/Package/PackageTmp/web.config"
        $script:newConfigName = $script:aspNetConfigName
        $script:webArchiveContentPath = "Content/*/obj/Release/Package/PackageTmp/bin/"
    }

    Extract-DirectoryFromZip -zip $package -directory $webArchiveContentPath -destination "$orchestratorPayloadTempDir/"

    $script:databaseMigrationToolPath = Join-Path $orchestratorPayloadTempDir "UiPath.Orchestrator.Setup.DatabaseMigration.Console.exe"
    $script:extensionsValidationToolPath = Join-Path $orchestratorPayloadTempDir "UiPath.Orchestrator.Setup.ExtensionsValidation.Console.exe"
    $configurationMigrationAssemblyPath = Join-Path $orchestratorPayloadTempDir "UiPath.Orchestrator.Setup.ConfigurationMigration.dll"
    $script:newConfigPath = Join-Path $orchestratorPayloadTempDir $script:newConfigName

    try {
        $appDomainSetup = New-Object System.AppDomainSetup
        $appDomainSetup.ConfigurationFile = $script:newConfigPath
        $appDomainSetup.ApplicationBase = $orchestratorPayloadTempDir

        $script:appDomain = [System.AppDomain]::CreateDomain("DatabaseMigrator_" + [guid]::NewGuid().Guid , $null, $appDomainSetup);

        [System.Reflection.Assembly]::LoadFrom($configurationMigrationAssemblyPath) | Out-Null

    }
    catch {
        Write-Host "An error has occured while loading UiPath.Orchestrator.Setup.ConfigurationMigration.dll file."
        DisplayException $_.Exception
        Exit 1
    }

    $script:defaultFolderstoSkip = @(
        "\\App_Data"
    )
    $script:defaultFilesToSkip = @()

    $script:tempDirectory = Join-Path ([System.IO.Path]::GetTempPath()) "azuredeploy-$(Get-Date -f "yyyyMMddhhmmssfff")"

    New-Item -ItemType Directory -Path $script:tempDirectory | Out-Null

    $script:publishSettingsPath = Join-Path $script:tempDirectory "$appServiceName.PublishSettings"
    $script:webConfigPath = Join-Path $script:tempDirectory  "Web.config"
    $script:parametersXmlPath = Join-Path $script:tempDirectory "parameters.xml"
    $script:hotswap = $false

    Download-PublishProfile -outputPath $script:publishSettingsPath -slotName $productionSlotName

    $script:updateProductionDatabase = $true
    $script:updateSwapDatabase = $true

    if ($standbySlotName) {

        # determine if deployment can be done in hotswap slot with zero downtime for production slot
        # we need to get the production slot pending migrations

        $script:publishSettings = Get-PublishSettings $script:publishSettingsPath
        $script:ftpPublishProfile = Get-FtpPublishProfile $script:publishSettingsPath

        Download-ConfigurationFile $script:webConfigPath $script:ftpPublishProfile

        $script:productionPublishSettings = $script:publishSettings
        $script:productionWebConfigPath = Join-Path $script:tempDirectory "Web.Production.config"
        Copy-Item -Path $script:webConfigPath -Destination $script:productionWebConfigPath

        $downtimeMigrations = Get-PendingMigrations -connectionString $script:publishSettings.MigrationSettings.SQLDBConnectionString -webConfigPath $script:webConfigPath -configMigration 'Default' -withDowntimeOnly

        if ($testAutomationFeatureEnabled) {
            $downtimeTestAutomationMigrations = Get-PendingMigrations -connectionString $script:publishSettings.MigrationSettings.SQLTestAutomationDBConnectionString -webConfigPath $script:webConfigPath -configMigration 'TestAutomation' -withDowntimeOnly
        }

        if ($downtimeMigrations -or ($testAutomationFeatureEnabled -and $downtimeTestAutomationMigrations)) {
            Write-Host "Pending downtime database migrations found for $(if($downtimeMigrations) { 'Orchestrator' } else { 'TestAutomation'})." -ForegroundColor Yellow
            Write-Host "Cannot deploy in swapslot $standbySlotName. Deployment will be performed in $productionSlotName." -ForegroundColor Yellow
        } else {
            Write-Host "No pending downtime database migrations. Deployment will be performed in hotswap slot $standbySlotName with zero downtime." -ForegroundColor Green
            $migrations = Get-PendingMigrations -connectionString $script:publishSettings.MigrationSettings.SQLDBConnectionString -webConfigPath $script:webConfigPath -configMigration 'Default'
            if ($testAutomationFeatureEnabled) {
                $testAutomationMigrations = Get-PendingMigrations -connectionString $script:publishSettings.MigrationSettings.SQLTestAutomationDBConnectionString -webConfigPath $script:webConfigPath -configMigration 'TestAutomation'
            }

            if ($migrations -or ($testAutomationFeatureEnabled -and $testAutomationMigrations)) {
                Write-Host "Pending migrations for production database"
            } else {
                Write-Host "No pending migrations for production database"
                $script:updateProductionDatabase = $false
            }

            Download-PublishProfile -outputPath $script:publishSettingsPath -slotName $standbySlotName
            $publishSettings = Get-PublishSettings $script:publishSettingsPath

            $migrations = Get-PendingMigrations -connectionString $publishSettings.MigrationSettings.SQLDBConnectionString -webConfigPath $script:webConfigPath -configMigration 'Default'
            if ($testAutomationFeatureEnabled) {
                $testAutomationMigrations = Get-PendingMigrations -connectionString $publishSettings.MigrationSettings.SQLTestAutomationDBConnectionString -webConfigPath $script:webConfigPath -configMigration 'TestAutomation'
            }

            if ($migrations -or ($testAutomationFeatureEnabled -and $testAutomationMigrations)) {
                Write-Host "Pending migrations for swap database"
            } else {
                Write-Host "No pending migrations for swap database"
                $script:updateSwapDatabase = $false
            }

            $script:hotswap = $true
        }
    }

    $script:deploymentSlotName = if ($script:hotswap) { $standbySlotName } else { $productionSlotName }
    $script:fullAppServiceName = if ($script:hotswap) { "$appServiceName-$standbySlotName" } else { "$appServiceName-$productionSlotName" }
    $script:ftpPublishProfile = Get-FtpPublishProfile $script:publishSettingsPath

    $script:storageType = $storageType
    $script:packagesApiKey = $packagesApiKey
    $script:activitiesApiKey = $activitiesApiKey
    $script:storageLocation = $storageLocation
    $script:redisConnectionString = $redisConnectionString
    $script:loadBalancerUseRedis = $loadBalancerUseRedis
    $script:robotsElasticSearchUrl = $robotsElasticSearchUrl
    $script:robotsElasticSearchUsername = $robotsElasticSearchUsername
    $script:robotsElasticSearchPassword = $robotsElasticSearchPassword
    $script:robotsElasticSearchTargets = $robotsElasticSearchTargets
    $script:serverElasticSearchUrl = $serverElasticSearchUrl
    $script:serverElasticSearchDiagnosticsUsername = $serverElasticSearchDiagnosticsUsername
    $script:serverElasticSearchDiagnosticsPassword = $serverElasticSearchDiagnosticsPassword
    $script:serverElasticSearchIndex = $serverElasticSearchIndex
    $script:serverDefaultTargets = $serverDefaultTargets
    $script:azureSignalRConnectionString = $azureSignalRConnectionString
    $script:runPackageMigrator = $false;
    $script:instanceKey
    $script:bucketsFileSystemAllowlist = $bucketsFileSystemAllowlist
    $script:bucketsAvailableProviders = $bucketsAvailableProviders

    Extract-FilesFromZip -zip $package -destinationFolder $script:tempDirectory -filePattern "parameters.xml"
    $script:defaultParameterXmlValues = Get-AllDefaultParameterValues -parametersXmlPath $script:parametersXmlPath
    if ($redisConnectionString) {
        $script:loadBalancerUseRedis = "true"
    }

    $script:existingProdAppSettings = Read-ExistingAppSettings $productionSlotName

    switch ($action) {
        "Update" {
            Download-ConfigurationFile $script:webConfigPath $script:ftpPublishProfile

            if (!($packagesApiKey)) {
                $script:packagesApiKey = (Get-WDParameterValue "apiKey" $script:parametersXmlPath $script:webConfigPath)
            }
            if (!($activitiesApiKey)) {
                $script:activitiesApiKey = (Get-WDParameterValue "activitiesApiKey" $script:parametersXmlPath $script:webConfigPath)
            }
            $script:decryption = (Get-WDParameterValue "machineKeyDecryption" $script:parametersXmlPath $script:webConfigPath)
            $script:decryptionKey = (Get-WDParameterValue "machineKeyDecryptionKey" $script:parametersXmlPath $script:webConfigPath)
            $script:validation = (Get-WDParameterValue "machineKeyValidation" $script:parametersXmlPath $script:webConfigPath)
            $script:validationKey = (Get-WDParameterValue "machineKeyValidationKey" $script:parametersXmlPath $script:webConfigPath)
            $script:encryptionKey = (Get-WDParameterValue "EncryptionKey" $script:parametersXmlPath $script:webConfigPath)

            if (!($storageType)) {
                $script:storageType = (Get-WDParameterValue "storageType" $script:parametersXmlPath $script:webConfigPath)
                if (!($script:storageType)) {
                    $script:storageType = $script:defaultParameterXmlValues."storageType"
                }
            }
            if (!($storageLocation)) {
                $script:storageLocation = (Get-WDParameterValue "storageLocation" $script:parametersXmlPath $script:webConfigPath)
                if (!($script:storageLocation)) {
                    $script:storageLocation = $script:defaultParameterXmlValues."storageLocation"
                }
            }
            if (!($redisConnectionString)) {
                $script:redisConnectionString = (Get-WDParameterValue "loadBalancerRedisConnectionString" $script:parametersXmlPath $script:webConfigPath)
                if (!($loadBalancerUseRedis)) {
                    $script:loadBalancerUseRedis = (Get-WDParameterValue "loadBalancerUseRedis" $script:parametersXmlPath $script:webConfigPath)
                }
            }
            if (!($robotsElasticSearchUrl)) {
                $script:robotsElasticSearchUrl = (Get-WDParameterValue "ElasticSearchUrl" $script:parametersXmlPath $script:webConfigPath)
            }
            if (!($robotsElasticSearchUsername)) {
                $script:robotsElasticSearchUsername = (Get-WDParameterValue "ElasticSearchUsername" $script:parametersXmlPath $script:webConfigPath)
            }
            if (!($robotsElasticSearchPassword)) {
                $script:robotsElasticSearchPassword = (Get-WDParameterValue "ElasticSearchPassword" $script:parametersXmlPath $script:webConfigPath)
            }
            if (!($robotsElasticSearchTargets)) {
                $script:robotsElasticSearchTargets = (Get-WDParameterValue "ElasticSearchLogger" $script:parametersXmlPath $script:webConfigPath)
            }
            if (!($serverElasticSearchUrl)) {
                $script:serverElasticSearchUrl = (Get-WDParameterValue "elasticSearchDiagnosticsUrl" $script:parametersXmlPath $script:webConfigPath)
            }
            if (!($serverElasticSearchDiagnosticsUsername)) {
                $script:serverElasticSearchDiagnosticsUsername = (Get-WDParameterValue "elasticSearchDiagnosticsUsername" $script:parametersXmlPath $script:webConfigPath)
            }
            if (!($serverElasticSearchDiagnosticsPassword)) {
                $script:serverElasticSearchDiagnosticsPassword = (Get-WDParameterValue "elasticSearchDiagnosticsPassword" $script:parametersXmlPath $script:webConfigPath)
            }
            if (!($serverElasticSearchIndex)) {
                $script:serverElasticSearchIndex = (Get-WDParameterValue "elasticSearchDiagnosticsIndex" $script:parametersXmlPath $script:webConfigPath)
            }
            if (!($serverDefaultTargets)) {
                $script:serverDefaultTargets = (Get-WDParameterValue "serverDefaultTargets" $script:parametersXmlPath $script:webConfigPath)
            }
            if (!($azureSignalRConnectionString)) {
                $script:azureSignalRConnectionString = (Get-WDParameterValue "azureSignalRConnectionString" $script:parametersXmlPath $script:webConfigPath)
            }
            if (!($bucketsFileSystemAllowlist)) {
                $script:bucketsFileSystemAllowlist = (Get-WDParameterValue "bucketsFileSystemAllowlist" $script:parametersXmlPath $script:webConfigPath)
            }
            if (!($bucketsAvailableProviders)) {
                $script:bucketsAvailableProviders = (Get-WDParameterValue "bucketsAvailableProviders" $script:parametersXmlPath $script:webConfigPath)
            }

            $script:nugetRepositoryType = Get-SettingValue "NuGet.Repository.Type" $script:webConfigPath
            $script:packagesUrl = Get-SettingValue "NuGet.Packages.Path" $script:webConfigPath
            $script:activitiesUrl = Get-SettingValue "NuGet.Activities.Path" $script:webConfigPath


            if (($script:nugetRepositoryType -eq "Legacy") -or #upgrade from legacy Orchestrator version > 19.4
                #upgrade from legacy Orchestrator version = 18.4.x, where NuGet.Repository.Type is missing
                (!($script:nugetRepositoryType) -and $script:packagesUrl -and $script:activitiesUrl)) {
                    $script:runPackageMigrator = $true
                    $script:instanceKey = Get-SettingValue "InstanceKey" $script:webConfigPath

                    if(!$script:instanceKey) {
                        $script:instanceKey = Generate-Guid
                    }

                    Write-Host "Current Nuget.Repository.Type is Legacy. Will run package migration."
                    Write-Verbose "NuGet.Packages.Path: $packagesUrl"
                    Write-Verbose "NuGet.Activities.Path: $activitiesUrl"
            }
        }
        "Deploy" {
            $script:packagesApiKey = Generate-Guid
            $script:activitiesApiKey = $script:packagesApiKey
            $script:nugetRepositoryType = "Composite"

            if (!$storageType) {
                $script:storageType = $script:defaultParameterXmlValues."storageType"
            }
            if (!$storageLocation) {
                $script:storageLocation = $script:defaultParameterXmlValues."storageLocation"
            }
        }
    }

}

function ValidateRequiredParameter($paramName, $paramValue) {
    if (!$paramValue){
        Write-Error "Error: Parameter -$paramName is required"
        return $false
    }
    return $true
}

function Validate-Parameters {

    if (!(Test-Path $script:msDeployExe)) {
        Write-Error "No msdeploy.exe found at '$($script:msDeployExe)'"
        Exit 1
    }

    $validStorageTypes = @("FileSystem", "Azure", "Minio", "Amazon")
    if ($script:storageType) {
        if ($validStorageTypes -notcontains $script:storageType) {
            Write-Error "Invalid -storageType parameter value. Valid values are: $validStorageTypes"
            Exit 1
        }
    }

    $validUseLoadBalancerValues = @("true","false")

    if ($script:loadBalancerUseRedis) {
        if ($validUseLoadBalancerValues -notcontains $script:loadBalancerUseRedis) {
            Write-Error "Invalid -loadBalancerUseRedis parameter value. Valid values are: $validUseLoadBalancerValues"
            Exit 1
        }
    }

    if ($action -eq "Update") {

        $updateErrorMessage = "The -{0} parameter is missing from web.config and is required if the -action parameter is set to 'Update'"

        if (!$script:storageLocation) {
            Write-Error ($updateErrorMessage -f "storageLocation")
            Exit 1
        }
        if (!$script:packagesApiKey) {
            Write-Error ($updateErrorMessage -f "packagesApiKey")
            Exit 1
        }
        if (!$script:activitiesApiKey) {
            Write-Error ($updateErrorMessage -f "activitiesApiKey")
            Exit 1
        }
    }

    if ($action -eq "Deploy"){

        if (!(ValidateRequiredParameter "hostAdminPassword" $hostAdminPassword) -or !(ValidateRequiredParameter "defaultTenantAdminPassword" $defaultTenantAdminPassword)) {
            Exit 1
        }

        $pwdValidationDesc = "Password must contain digits, lowercase chars and be at least 8 characters long"
        $pwdValidationRe = "(?=.*\d)(?=.*[a-z]).{8,}"

        if (-not ($hostAdminPassword -cmatch $pwdValidationRe))
        {
            Write-Error "Host admin password is not strong enough: $pwdValidationDesc"
            Exit 1
        }

        if (-not ($defaultTenantAdminPassword -cmatch $pwdValidationRe))
        {
            Write-Error "Default tenant admin password is not strong enough: $pwdValidationDesc"
            Exit 1
        }
    }

    if (!(Test-Path $script:publishSettingsPath)) {

        $publishSettingsErrorMessage = "The -{0} parameter is required if the publish file is not present"

        if (!$website) {
            Write-Error ($publishSettingsErrorMessage -f "website")
            Exit 1
        }

        if (!$publishUrl) {
            Write-Error ($publishSettingsErrorMessage -f "publishUrl")
            Exit 1
        }

        if (!$username) {
            Write-Error ($publishSettingsErrorMessage -f "username")
            Exit 1
        }

        if (!$password) {
            Write-Error ($publishSettingsErrorMessage -f "password")
            Exit 1
        }

        if (!$connectionString) {
            Write-Error ($publishSettingsErrorMessage -f "connectionString")
            Exit 1
        }

        if (!$ftpPublishUrl) {
            Write-Error ($publishSettingsErrorMessage -f "ftpPublishUrl")
            Exit 1
        }

        if (!$ftpUsername) {
            Write-Error ($publishSettingsErrorMessage -f "ftpUsername")
            Exit 1
        }

        if (!$ftpPassword) {
            Write-Error ($publishSettingsErrorMessage -f "ftpPassword")
            Exit 1
        }

    }

    if ($activitiesPackagePath -and ($nugetRepositoryType -eq "Composite")) {
        if (!$packageMigratorPath) {
            Write-Error "The -packageMigratorPath parameter is required if -activitiesPackagePath is provided"
            Exit 1
        }
    }

    if ($runPackageMigrator) {
        if (!$packageMigratorPath) {
            if ((Test-Path ".\ps_utils\UiPath.Orchestrator.PackagesMigrator.zip")) {
                $packageMigratorPath =  [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($workingFolder, ".\ps_utils\UiPath.Orchestrator.PackagesMigrator.zip" ))
            } else {
                Write-Error "The -packageMigratorPath parameter is required if current Nuget.Repository.Type setting is set to Legacy"
                Exit 1
            }
        }

        if (!$script:storageType -or !$script:storageLocation) {
             Write-Error "Both -storageType and -storageLocation parameters are required if current Nuget.Repository.Type setting is set to Legacy. NuGet packages need to be migrated to a new location."
        }

        if (!$script:packagesUrl -or !$script:activitiesUrl) {
             Write-Error "Both `NuGet.Packages.Path` and `NuGet.Activities.Path` settings are required to be set either in web.config or Application Settings, if current `Nuget.Repository.Type` setting is set to Legacy. NuGet packages need to be migrated from the existing locations."
        }

        $script:packageMigratorPath = Extract-PackageMigratorToTempFolder
    }

    if(($script:bucketsAvailableProviders -like '*FileSystem*') -and ($null -eq $script:bucketsFileSystemAllowlist)){
        Write-Error "The -bucketsFileSystemAllowlist is mandatory when -bucketsAvailableProviders contains FileSystem provider"
        Exit 1
    }
}

function AuthenticateToAzure {

    $securePassword = $azureAccountPassword | ConvertTo-SecureString -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($azureAccountApplicationId, $securePassword)
    Write-Host "Attempting log in to AzureRM"
    if ($azureUSGovernmentLogin) {
        $loginResult = Login-AzureRmAccount `
            -ServicePrincipal `
            -SubscriptionId $azureSubscriptionId `
            -TenantId $azureAccountTenantId `
            -Credential $credential `
            -Environment AzureUSGovernment
    } else {
        $loginResult = Login-AzureRmAccount `
            -ServicePrincipal `
            -SubscriptionId $azureSubscriptionId `
            -TenantId $azureAccountTenantId `
            -Credential $credential
    }
    if ($loginResult){
        Write-Host "Logged in to AzureRM" -ForegroundColor Green
    } else {
        Write-Error "Failed to log in to AzureRM"
        Exit 1
    }

}

function StopWebApplication ([string] $slotName) {

    $stopped = Stop-AzureRmWebAppSlot -ResourceGroupName $resourceGroupName -Name $appServiceName -Slot $slotName.Trim()

    if ($stopped){
        Write-Host "Stopped the application $script:fullAppServiceName"
    } else {
        Write-Error "Could not stop the application $script:fullAppServiceName, aborting."
        Exit 1
    }
    Write-Host "Waiting 30 seconds for $script:fullAppServiceName to shut down completely."
    Start-Sleep -Seconds 30
}

function StartWebApplication([string] $slotName) {

    $started = Start-AzureRmWebAppSlot -ResourceGroupName $resourceGroupName -Name $appServiceName -Slot $slotName

    if ($started){
        Write-host "Started the application $script:fullAppServiceName"
    } else {
        Write-Error "Could not start the application $script:fullAppServiceName, try to start it manually."
    }
}

function Deploy-Package($package, $publishSettings) {

    if (($action -eq "Deploy") -and !$unattended) {

        Write-Warning "`n`nYou are running a fresh deployment.`nThis means that all encryption settings will be generated and pushed to the target website.`nPlease make sure that you are not deploying over an existing website, to avoid losing any settings.`nIf you are trying to update an existing website, please rerun the script with the -action parameter set to 'Update'.`nThe following items will be generated:`n- Encryption key for credential assets`n- NuGet feed API key (for published packages and Activities)`n- Website machine key (IIS)"

        if (!(Prompt-ForContinuation)) {
            Write-Host "`nExiting...`n" -ForegroundColor Yellow
            Exit 0
        }
    }

    $skipFolders = $foldersToSkip + $script:defaultFolderstoSkip
    $skipFiles = $filesToSkip + $script:defaultFilesToSkip

    $wdParameters = Get-WDParameters
    $publishParameters = $null

    try {

        Write-Host "`nDeploying package $package on website $($publishSettings.SiteName)" -ForegroundColor Yellow

        Write-Host "`nWeb Deploy parameters:" -ForegroundColor Yellow
        Write-Host ($wdParameters | Out-String)

        Write-Host "Folders to skip:`n" -ForegroundColor Yellow
        Write-Host ($skipFolders -join ", ")

        Write-Host "`nFiles to skip:`n" -ForegroundColor Yellow
        Write-Host ($skipFiles -join ", ")

        $args = Build-MsDeployArgs `
            -parameters $wdParameters `
            -skipFolders $skipFolders `
            -skipFiles $skipFiles `
            -publishSettings $publishSettings

        Write-Host "`nExecuting command:`n" -ForegroundColor Yellow
        Write-Host "msdeploy.exe $args`n"

        $shouldContinue = $unattended -or (Prompt-ForContinuation)

        if (!$shouldContinue) {
            Write-Host "`nExiting...`n" -ForegroundColor Yellow
            Exit 0
        }

        $proccess = Start-Process $script:msDeployExe -ArgumentList $args -Wait -NoNewWindow -PassThru

        if ($proccess.ExitCode) {
          Write-Error "`nFailed to deploy package $package"
          Exit 1
        }

        Write-Host "`nPackage $package deployed successfully" -ForegroundColor Green

        $publishParameters = Get-PublishParameters $wdParameters $applicationSettings
        $publishParameters | ConvertTo-Json -Depth 99 | Out-File $parametersOutputPath

        Write-Host "`nDeployment parameters logged in file '$parametersOutputPath'`n" -ForegroundColor Yellow

    } catch {
        DisplayException $_.Exception
        Exit 1
    }
}

function Build-MsDeployArgs([System.Collections.Hashtable] $parameters, [string[]] $skipFolders, [string[]] $skipFiles, $publishSettings) {

    $site = $publishSettings.SiteName
    $publishUrl = $publishSettings.PublishUrl
    $username = $publishSettings.UserName
    $password = $publishSettings.Password

    $msDeployArgs = "-verb:sync -source:package='$package' -dest:auto,ComputerName='https://$publishUrl/msdeploy.axd?site=$site',UserName='$userName',Password='$password',AuthType='Basic' -disableLink:AppPoolExtension -disableLink:ContentExtension -disableLink:CertificateExtension -setParam:name='IIS Web Application Name',value='$site'"

    $skipFolders | ForEach-Object {
        $msDeployArgs += " -skip:objectName=dirPath,absolutePath='$($_)'"
    }

    $skipFiles | ForEach-Object {
        $msDeployArgs += " -skip:filePath=dirPath,absolutePath='$($_)'"
    }

    $parameters.GetEnumerator() | ForEach-Object {
        $msDeployArgs += " -setParam:name='$($_.Key)',value='$($_.Value)'"
    }

    return $msDeployArgs
}

function Get-WDParameters {

    $wdParameters = @{
        ElasticSearchRequireAuth = "false"
        elasticSearchDiagnosticsRequireAuth = "false"
    }

    $encryptionKeyToSet = if ($action -eq "Deploy") {
        Generate-EncryptionKey
    } else {
        $script:encryptionKey
    }
    $wdParameters.EncryptionKey = $encryptionKeyToSet

    $machineKeySettings = Get-MachineKeySettings
    $wdParameters.machineKeyDecryption = $machineKeySettings.decryption
    $wdParameters.machineKeyDecryptionKey = $machineKeySettings.decryptionKey
    $wdParameters.machineKeyValidation = $machineKeySettings.validation
    $wdParameters.machineKeyValidationKey = $machineKeySettings.validationKey

    if ([boolean]$script:redisConnectionString) {
        $wdParameters.loadBalancerUseRedis = $script:loadBalancerUseRedis
        $wdParameters.loadBalancerRedisConnectionString = $script:redisConnectionString
    }

    if ($script:robotsElasticSearchUrl) {
        $wdParameters.ElasticSearchUrl = $script:robotsElasticSearchUrl
        $wdParameters.ElasticSearchLogger = "$script:robotsElasticSearchTargets"

        if ($script:robotsElasticSearchUsername -and $script:robotsElasticSearchPassword) {
            $wdParameters.ElasticSearchUsername = $script:robotsElasticSearchUsername
            $wdParameters.ElasticSearchPassword = $script:robotsElasticSearchPassword
            $wdParameters.ElasticSearchRequireAuth = "true"
        }
    }

    if ($script:serverDefaultTargets) {
        $wdParameters.serverDefaultTargets = "$script:serverDefaultTargets"
    }

    if ($script:serverElasticSearchUrl) {
        $wdParameters.elasticSearchDiagnosticsUrl = $script:serverElasticSearchUrl

        if ($script:serverElasticSearchIndex) {
            $wdParameters.elasticSearchDiagnosticsIndex = $script:serverElasticSearchIndex
        }

        if ($script:serverElasticSearchDiagnosticsUsername -and $script:serverElasticSearchDiagnosticsPassword) {
            $wdParameters.elasticSearchDiagnosticsUsername = $script:serverElasticSearchDiagnosticsUsername
            $wdParameters.elasticSearchDiagnosticsPassword = $script:serverElasticSearchDiagnosticsPassword
            $wdParameters.elasticSearchDiagnosticsRequireAuth = "true"
        }
    }

    if ($useQuartzClustered) {
        $wdParameters.quartzJobStoreClustered = "true"
    }

    $wdParameters.storageType = $script:storageType
    $wdParameters.storageLocation = $script:storageLocation
    $wdParameters.apiKey = $packagesApiKey
    $wdParameters.activitiesApiKey = $activitiesApiKey

    if ($script:azureSignalRConnectionString) {
        $wdParameters.azureSignalRConnectionString = $script:azureSignalRConnectionString
    }
    if ($script:bucketsFileSystemAllowlist) {
        $wdParameters.bucketsFileSystemAllowlist = $script:bucketsFileSystemAllowlist
    }
    if ($script:bucketsAvailableProviders) {
        $wdParameters.bucketsAvailableProviders = $script:bucketsAvailableProviders
    }
    return $wdParameters
}

function Get-MachineKeySettings() {

    if ($action -eq "Deploy") {
        return (Generate-MachineKeySettings)
    }

    return @{
        decryption = $script:decryption;
        decryptionKey = $script:decryptionKey;
        validation = $script:validation;
        validationKey = $script:validationKey;
    }
}

function Generate-MachineKeySettings {

    [CmdletBinding()]
    param (
        [ValidateSet("AES", "DES", "3DES")]
        [string] $decryptionAlgorithm = 'AES',
        [ValidateSet("MD5", "SHA1", "HMACSHA256", "HMACSHA384", "HMACSHA512")]
        [string] $validationAlgorithm = 'HMACSHA256'
    )

    process {

        function BinaryToHex {

            [CmdLetBinding()]
            param($bytes)

            process {

                $builder = new-object System.Text.StringBuilder

                foreach ($b in $bytes)
                {
                    $builder = $builder.AppendFormat([System.Globalization.CultureInfo]::InvariantCulture, "{0:X2}", $b)
                }

                $builder
            }
        }

        switch ($decryptionAlgorithm) {
            "AES" { $decryptionObject = new-object System.Security.Cryptography.AesCryptoServiceProvider }
            "DES" { $decryptionObject = new-object System.Security.Cryptography.DESCryptoServiceProvider }
            "3DES" { $decryptionObject = new-object System.Security.Cryptography.TripleDESCryptoServiceProvider }
        }

        $decryptionObject.GenerateKey()
        $decryptionKey = BinaryToHex($decryptionObject.Key)
        $decryptionObject.Dispose()

        switch ($validationAlgorithm) {
            "MD5" { $validationObject = new-object System.Security.Cryptography.HMACMD5 }
            "SHA1" { $validationObject = new-object System.Security.Cryptography.HMACSHA1 }
            "HMACSHA256" { $validationObject = new-object System.Security.Cryptography.HMACSHA256 }
            "HMACSHA385" { $validationObject = new-object System.Security.Cryptography.HMACSHA384 }
            "HMACSHA512" { $validationObject = new-object System.Security.Cryptography.HMACSHA512 }
        }

        $validationKey = BinaryToHex($validationObject.Key)

        $validationObject.Dispose()

        return @{
            decryption = $decryptionAlgorithm.ToUpperInvariant();
            decryptionKey = $decryptionKey.ToString();
            validation = $validationAlgorithm.ToUpperInvariant();
            validationKey = $validationKey.ToString();
        }
    }
}
function Generate-EncryptionKey {

    $encrypter = New-Object System.Security.Cryptography.AesCryptoServiceProvider

    $encrypter.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $encrypter.BlockSize = 128
    $encrypter.KeySize = 256

    $encrypter.GenerateKey()

    $generateKey = [System.Convert]::ToBase64String($encrypter.Key)

    return $generateKey
}

function Generate-Guid {

    return ([guid]::NewGuid().Guid)
}

function Get-FtpPublishProfile([string] $publishPath) {

    $publishSettingsXml = New-Object System.Xml.XmlDocument

    $publishSettingsXml.Load($publishPath)

    $publishSettings = @{
        FtpPublishUrl = $publishSettingsXml.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@publishUrl").value;
        FtpUsername = $publishSettingsXml.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userName").value;
        FtpPassword = $publishSettingsXml.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userPWD").value;
    }

    return $publishSettings
}

function Get-PublishSettings($publishPath) {

    $publishSettings = if ($publishPath -and (Test-Path $publishPath)) {
        Get-WDPublishSettings -FileName $publishPath
    } else {
        @{
            SiteName = $website;
            PublishUrl = $publishUrl;
            UserName = $username;
            Password = $password;
        }
    }

    $migrationSettings = @{}

    if ($publishPath -and (Test-Path $publishPath)) {
        [xml]$profile = Get-Content -Path $publishPath
        $migrationSettings = @{
            SQLDBConnectionString = $profile.SelectNodes("//publishData//publishProfile[@publishMethod=`"MSDeploy`"]//databases//add[@name='Default']/@connectionString").value;
            FtpPublishUrl = $profile.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@publishUrl").value;
            FtpUsername = $profile.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userName").value;
            FtpPassword = $profile.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userPWD").value;
        }
    } else {
        $migrationSettings = @{
            SQLDBConnectionString = $connectionString;
            FtpPublishUrl = $ftpPublishUrl;
            FtpUsername = $ftpUsername;
            FtpPassword = $ftpPassword;
        }
    }

    if ($testAutomationFeatureEnabled) {
        if ($publishPath -and (Test-Path $publishPath)) {
            $migrationSettings.SQLTestAutomationDBConnectionString = $profile.SelectNodes("//publishData//publishProfile[@publishMethod=`"MSDeploy`"]//databases//add[@name='TestAutomation']/@connectionString").value;
        }
    } else {
        $migrationSettings.SQLTestAutomationDBConnectionString = $testAutomationConnectionString
    }

    return @{
        PublishSettings = $publishSettings;
        MigrationSettings = $migrationSettings;
    }
}

function Get-PublishParameters($wdParameters, $appSettings) {

    $publishParameters = @{
        encryptionKey = $wdParameters.EncryptionKey;
        packagesApiKey = $wdParameters.apiKey;
        activitiesApiKey = $wdParameters.activitiesApiKey;

        robotsElasticSearchUrl = $wdParameters.ElasticSearchUrl;
        robotsElasticSearchUsername = $wdParameters.ElasticSearchUsername;
        robotsElasticSearchPassword = $wdParameters.ElasticSearchPassword;
        robotsElasticSearchTargets = $wdParameters.ElasticSearchLogger;
        serverElasticSearchUrl = $wdParameters.elasticSearchDiagnosticsUrl;
        serverElasticSearchIndex = $wdParameters.elasticSearchDiagnosticsIndex;
        serverDefaultTargets = $wdParameters.serverDefaultTargets;
        serverElasticSearchDiagnosticsUsername = $wdParameters.elasticSearchDiagnosticsUsername;
        serverElasticSearchDiagnosticsPassword = $wdParameters.elasticSearchDiagnosticsPassword;
        azureSignalRConnectionString = $wdParameters.azureSignalRConnectionString;
        bucketsFileSystemAllowlist = $wdParameters.bucketsFileSystemAllowlist;
        bucketsAvailableProviders = $wdParameters.bucketsAvailableProviders;
    }

    $publishParameters.machineKeyDecryption = $wdParameters.machineKeyDecryption;
    $publishParameters.machineKeyDecryptionKey = $wdParameters.machineKeyDecryptionKey;
    $publishParameters.machineKeyValidation = $wdParameters.machineKeyValidation;
    $publishParameters.machineKeyValidationKey = $wdParameters.machineKeyValidationKey;
    $publishParameters.storageType = $wdParameters.storageType
    $publishParameters.storageLocation = $wdParameters.storageLocations

    return $publishParameters
}

function Prompt-ForContinuation([string] $message = "Do you wish to continue?") {

    $value = ""

    while (($value.ToLowerInvariant() -notin @("y", "n"))) {
        $value = Read-Host "`n$message (y/n)"
    }

    return ($value.ToLowerInvariant() -eq "y")
}

function Download-ConfigurationFile([string] $outputPath, $ftpPublishProfile) {

    $fileDownloaded = Download-WebsiteFile -websiteFilePath $script:dotNetCoreConfigName -outputPath $outputPath -publishProfile $ftpPublishProfile
    if (!$fileDownloaded) {
        $fileDownloaded = Download-WebsiteFile -websiteFilePath $script:aspNetCoreConfigName -outputPath $outputPath -publishProfile $ftpPublishProfile
        if (!$fileDownloaded) {
            $fileDownloaded = Download-WebsiteFile -websiteFilePath $script:aspNetConfigName -outputPath $outputPath -publishProfile $ftpPublishProfile
        }
    }

    if($fileDownloaded) {
        Remove-ConfigBuilders -configFilePath $outputPath
        return $outputPath
    } else {
        throw "No configuration file was found in $($ftpPublishProfile.FtpPublishUrl)";
    }
}

function Download-File($url, $userName, $password, $outputPath) {

    Write-Verbose "Downloading file from URL $url to $outputPath"

	$webClient = New-Object System.Net.WebClient
    $webClient.Credentials = New-Object System.Net.NetworkCredential($userName.Normalize(), $password.Normalize())
    try {
        $webClient.DownloadFile($url, $outputPath)
        Write-Host "$fileName file downloaded successfully from $url"
        return $true
    }
    catch [System.Net.WebException] {
        Write-Host "$fileName file could not be downloaded"
        Write-Host $_.Exception.Message
        return $false
    }
}

function Update-AllDatabases($publishSettings) {
    try {
        if ($action -eq "Deploy") {
            Download-ConfigurationFile $script:webConfigPath $script:ftpPublishProfile
        }

        if ((!$script:hotswap -and $script:updateProductionDatabase) -or ($script:hotswap -and $script:updateSwapDatabase)) {
            Write-Host "Updating Databases for $deploymentSlotName"

            Run-DatabaseMigrations -databaseType "Default" -connectionString $publishSettings.MigrationSettings.SQLDBConnectionString -configFilePath $script:webConfigPath
            if ($testAutomationFeatureEnabled) {
                Run-DatabaseMigrations -databaseType "TestAutomation" -connectionString $publishSettings.MigrationSettings.SQLTestAutomationDBConnectionString -configFilePath $script:webConfigPath
            }
        }

        Write-Host "Initializing InternalJobs for $deploymentSlotName"
        Initialize-InternalJobs -databaseType "Default" -connectionString $publishSettings.MigrationSettings.SQLDBConnectionString -configFilePath $script:webConfigPath -slotName $deploymentSlotName

        if ($script:productionWebConfigPath){
            if ($action -eq "Deploy") {
                Download-ConfigurationFile $script:productionWebConfigPath $script:ftpPublishProfile
            }

            if ($script:hotswap -and $script:updateProductionDatabase) {
                Write-Host "Updating Database for $productionSlotName"

                Run-DatabaseMigrations -databaseType "Default" -connectionString $script:productionPublishSettings.MigrationSettings.SQLDBConnectionString -configFilePath $script:productionWebConfigPath
                if ($testAutomationFeatureEnabled) {
                    Run-DatabaseMigrations -databaseType "TestAutomation" -connectionString $script:productionPublishSettings.MigrationSettings.SQLTestAutomationDBConnectionString -configFilePath $script:productionWebConfigPath
                }
            }

            Write-Host "Initializing InternalJobs for $productionSlotName"
            Initialize-InternalJobs -databaseType "Default" -connectionString $script:productionPublishSettings.MigrationSettings.SQLDBConnectionString -configFilePath $script:productionWebConfigPath -slotName $productionSlotName
        }
    }
    catch {
        Write-Host "An error has occured while trying to cofigure the database."
        DisplayException $_.Exception
        Exit 1
    }
}

function Deploy-ActivitiesInCompositeMode($publishSettings) {

    $activitiesTempFolder = Extract-ActivitiesToTempFolder
    $activitiesLegacyFolder = Join-Path $activitiesTempFolder "legacy_$(Get-Date -Format 'yyyyMMddhhmmssffff')"

    New-Item -Path $activitiesLegacyFolder -ItemType "Directory" | Out-Null

    Build-LegacyActivitiesFolderStructure $activitiesTempFolder $activitiesLegacyFolder
    Write-Host "Migrating activities from folder $activitiesLegacyFolder"

    try {
        & $packageMigratorPath activities `
        --application-path $script:tempDirectory `
        --source-folder $activitiesLegacyFolder

       # Remove-Item $activitiesTempFolder -Recurse -Force | Out-Null

    } catch {
        DisplayException $_.Exception
        Exit 1
    }
}

function Extract-ActivitiesToTempFolder() {
    $tempDirectory = Join-Path $ENV:TEMP "oa_$(Get-Date -Format 'yyyyMMddhhmmssffff')"

    Extract-FilesFromZip -zip $activitiesPackagePath -destination "$tempDirectory/"

    return $tempDirectory
}

function Extract-PackageMigratorToTempFolder() {
     $tempDirectory = Join-Path $ENV:TEMP "oa_$(Get-Date -Format 'yyyyMMddhhmmssffff')"

    Extract-FilesFromZip -zip $packageMigratorPath -destination "$tempDirectory/"

    return $tempDirectory
}

function Build-LegacyActivitiesFolderStructure($activitiesFolder, $targetFolder) {

    $activityPackages = Get-ChildItem $activitiesFolder

    $legacyActivityPackagesFolder = (Join-Path $targetFolder "Activities")

    New-Item -Path $legacyActivityPackagesFolder -ItemType "Directory" | Out-Null

    foreach ($activityPackage in $activityPackages) {
        Write-Verbose "Analyzing $activityPackage ..."
        $activityInfo = Get-ActivityNameAndVersionFromFilePath $activityPackage.FullName
        $activityName = $activityInfo.Name
        $activityVersion = $activityInfo.Version

        $activityFolder = Join-Path $legacyActivityPackagesFolder "$($activityName)"
        if (!(Test-Path $activityFolder))
        {
            New-Item -Path $activityFolder -ItemType "Directory" | Out-Null
        }

        $activityFolderVersion = Join-Path $activityFolder "$($activityVersion)"
        if (!(Test-Path $activityFolderVersion))
        {
            New-Item -Path $activityFolderVersion  -ItemType "Directory" | Out-Null
        }

        Copy-Item -Path $activityPackage.FullName -Destination $activityFolderVersion
    }
}

function Get-ActivityNameAndVersionFromFilePath($filePath) {

    $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($filePath)

    $nameAndVersionPattern = "(.+)\.(\d+\.\d+\.\d+-*.*)`$"

    $name = $fileNameWithoutExtension -replace $nameAndVersionPattern,"`$1"
    $version = $fileNameWithoutExtension -replace $nameAndVersionPattern,"`$2"

    $activityInfo = @{
        Name = $name;
        Version = $version;
    }

    return $activityInfo
}

function Extract-DirectoryFromZip {
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $zip,

        [Parameter(Mandatory = $true, Position = 2)]
        [string] $directory,

        [Parameter(Mandatory = $true, Position = 3)]
        [string] $destination,

        [switch] $preserveStructure
    )

    [Void][Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')

    if (![System.IO.Path]::IsPathRooted($destination))
    {
        throw "The destination path must be an absolute path ($destination)"
    }

    if (!(Test-Path $destination))
    {
        New-Item -ItemType Directory -Path $destination | Out-Null
    }

    [System.IO.Compression.ZipArchive] $zipFile = [System.IO.Compression.ZipFile]::OpenRead($zip)

    $directoryPattern = if ($directory.EndsWith('/')) {
        $directory + '*'
    } else {
        $directory + '/*'
    }

    foreach ($entry in $zipFile.Entries)
    {
        if ($entry.FullName -like $directoryPattern)
        {
            $entryIsDirectory = !$entry.Name
            $entryDestination = (Join-Path $destination $($entry.FullName)) -replace "\\","/"

            if (!$preserveStructure)
            {
                $prefixPattern = $directory -replace '\*','.+'

                $entryDestination = $entryDestination -replace $prefixPattern,''
            }

            if ($entryIsDirectory)
            {
                if (!(Test-Path $entryDestination))
                {
                    New-Item -ItemType Directory -Path $entryDestination | Out-Null
                }
            }
            else
            {
                $entryDestinationDirectory = Split-Path -Path $entryDestination -Parent

                if (!(Test-Path $entryDestinationDirectory))
                {
                    New-Item -ItemType Directory -Path $entryDestinationDirectory | Out-Null
                }

                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $entryDestination, $true)
            }

        }
    }
}

function Extract-FilesFromZip {
    param(
        [Parameter(Mandatory = $true, Position = 1)]  #there are no folders inside archive, only files
        [string] $zipPath,

        [Parameter(Mandatory = $true, Position = 2)]
        [string] $destinationFolder,

        [string] $filePattern
    )

    [Void][Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')

    if (![System.IO.Path]::IsPathRooted($destinationFolder))
    {
        throw "The destination path must be an absolute path ($destinationFolder)"
    }

    if (!(Test-Path $destinationFolder))
    {
        New-Item -ItemType Directory -Path $destinationFolder | Out-Null
    }

    [System.IO.Compression.ZipArchive] $zipFile = [System.IO.Compression.ZipFile]::OpenRead($zipPath)

    foreach ($entry in $zipFile.Entries)
    {
        if (!$filePattern -or $entry.FullName -like $filePattern){
            $entryDestination = Join-Path $destinationFolder $($entry.Name)

            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $entryDestination, $true)
        }
    }
}

function Get-PendingMigrations {
    param(
        [Parameter(Mandatory = $true)]
        [string] $connectionString,

        [Parameter(Mandatory = $true)]
        [string] $webConfigPath,

        [Parameter(Mandatory = $true)][ValidateSet('Default', 'TestAutomation')]
        [string] $configMigration,

        [Parameter(Mandatory = $false)]
        [switch] $withDowntimeOnly = $false
    )

    try {
        $migrationsTypeMessage = ""
        $arguments = "get-pending-migrations --database-type $configMigration --connection-string `"$connectionString`" --configuration-path `"$webConfigPath`""
        if ($withDowntimeOnly) {
            $arguments += " --with-downtime "
            $migrationsTypeMessage = "with downtime"
        }

        $getMigrationsProcess = Invoke-Executable -exeFile $databaseMigrationToolPath -args $arguments

        Write-Verbose "Process finished. Exit code: $($getMigrationsProcess.ExitCode)"
        Write-ProcessStd $getMigrationsProcess $true

        if($getMigrationsProcess.ExitCode -ne 0) {
            Write-Host "Process finished with error." -ForegroundColor Red
            throw "Getting pending migrations $migrationsTypeMessage failed. Returned exit code $($getMigrationsProcess.ExitCode)";
        }
        else {
            Write-Verbose "Process finished successfully."
            if (-not [string]::IsNullOrWhitespace($getMigrationsProcess.StdOut)) {
                if ($getMigrationsProcess.StdOut -match "Number of pending migrations: (\d+)\.") {
                    if (($Matches[1] -as [int]) -gt 0) {
                        Write-Verbose "Found pending database migrations $migrationsTypeMessage."
                        return $true
                    }
                }
            }

            Write-Verbose "No $configMigration Migrations $migrationsTypeMessage pending."
            return $false
        }
    }
    catch {
        DisplayException $_.Exception.Message
        Write-Error "An error has occured while trying to get pending $configMigration database migrations."
    }
}

function Run-DatabaseMigrations ($databaseType, $connectionString, $configFilePath) {

    Write-Host "Running database migrations"

    $migrationArguments = "upgrade-database --database-type $databaseType --connection-string `"$connectionString`" --configuration-path `"$configFilePath`""
    if ($databaseType -eq "Default" -And $action -eq "Deploy") {
        $migrationArguments += " --host-admin-password $hostAdminPassword --tenant-admin-password $defaultTenantAdminPassword"
        if ($isHostPassOneTime) {
            $migrationArguments += " --change-host-admin-password"
        }
        if ($isDefaultTenantPassOneTime) {
            $migrationArguments += " --change-tenant-admin-password"
        }
    }

    $migrationProcess = Invoke-Executable -exeFile $databaseMigrationToolPath `
                                          -args $migrationArguments

    Write-Host "Process finished. Exit code: $($migrationProcess.ExitCode)"
    Write-ProcessStd $migrationProcess
    if($migrationProcess.ExitCode -ne 0) {
        Write-Host "Process finished with error." -ForegroundColor Red
        throw "Database migration returned exit code $($migrationProcess.ExitCode)";
    }
    else {
        Write-Host "Process finished successfully."
    }

    Write-Host "Validating database"
    $validationProcess = Invoke-Executable -exeFile $databaseMigrationToolPath `
                                           -args "validate-database --database-type $databaseType --connection-string `"$connectionString`" --configuration-path `"$configFilePath`""

    Write-Host "Process finished. Exit code: $($validationProcess.ExitCode)"
    Write-ProcessStd $validationProcess
    if($validationProcess.ExitCode -ne 0) {
        Write-Host "Some issues were detected while validating the database. This error is not fatal. Publish will continue. Exit code: $($validationProcess.ExitCode)" -ForegroundColor Yellow
    }
}

function Initialize-InternalJobs ($databaseType, $connectionString, $configFilePath, $slotName) {
    Write-Host "Initializing InternalJobs for $databaseType on slot $slotName"
    $initJobsProcess = Invoke-Executable -exeFile $databaseMigrationToolPath `
                                         -args "recreate-internal-jobs --database-type $databaseType --connection-string `"$connectionString`" --configuration-path `"$configFilePath`""

    Write-Host "Process finished. Exit code: $($initJobsProcess.ExitCode)"
    Write-ProcessStd $initJobsProcess
    if($initJobsProcess.ExitCode -ne 0) {
        Write-Host "Process finished with error." -ForegroundColor Red
        throw "Initializing InternalJobs returned exit code $($initJobsProcess.ExitCode)";
    }
    else {
        Write-Host "InternalJobs for $databaseType initialized on slot $slotName."
    }
}

function Invoke-Executable {
    # Runs the specified executable and captures its exit code, stdout
    # and stderr.
    # Returns: custom object.
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$exeFile,
        [Parameter(Mandatory=$false)]
        [String[]]$args,
        [Parameter(Mandatory=$false)]
        [String]$verb,
        [Parameter(Mandatory=$false)]
        [Int]$timeoutMilliseconds=1800000 #30min
    )

    Write-Host $exeFile $args

    # Setting process invocation parameters.
    $oPsi = New-Object -TypeName System.Diagnostics.ProcessStartInfo
    $oPsi.CreateNoWindow = $true
    $oPsi.UseShellExecute = $false
    $oPsi.RedirectStandardOutput = $true
    $oPsi.RedirectStandardError = $true
    $oPsi.FileName = $exeFile
    if (! [String]::IsNullOrEmpty($args)) {
        $oPsi.Arguments = $args
    }
    if (! [String]::IsNullOrEmpty($verb)) {
        $oPsi.Verb = $verb
    }

    # Creating process object.
    $oProcess = New-Object -TypeName System.Diagnostics.Process
    $oProcess.StartInfo = $oPsi

    # Creating string builders to store stdout and stderr.
    $oStdOutBuilder = New-Object -TypeName System.Text.StringBuilder
    $oStdErrBuilder = New-Object -TypeName System.Text.StringBuilder

    # Adding event handers for stdout and stderr.
    $sScripBlock = {
        if (! [String]::IsNullOrEmpty($EventArgs.Data)) {
            $Event.MessageData.AppendLine($EventArgs.Data)
        }
    }
    $oStdOutEvent = Register-ObjectEvent -InputObject $oProcess `
        -Action $sScripBlock -EventName 'OutputDataReceived' `
        -MessageData $oStdOutBuilder
    $oStdErrEvent = Register-ObjectEvent -InputObject $oProcess `
        -Action $sScripBlock -EventName 'ErrorDataReceived' `
        -MessageData $oStdErrBuilder

    # Starting process.
    [Void]$oProcess.Start()
    $oProcess.BeginOutputReadLine()
    $oProcess.BeginErrorReadLine()
    $bRet=$oProcess.WaitForExit($TimeoutMilliseconds)
    if (-Not $bRet)
    {
        $oProcess.Kill();
        throw [System.TimeoutException] ($exeFile + " was killed due to timeout after " + ($TimeoutMilliseconds/1000) + " sec ")
    }
    # Unregistering events to retrieve process output.
    Unregister-Event -SourceIdentifier $oStdOutEvent.Name
    Unregister-Event -SourceIdentifier $oStdErrEvent.Name

    $oResult = New-Object -TypeName PSObject -Property ([Ordered]@{
        "ExeFile"  = $exeFile;
        "Args"     = $args -join " ";
        "ExitCode" = $oProcess.ExitCode;
        "StdOut"   = $oStdOutBuilder.ToString().Trim();
        "StdErr"   = $oStdErrBuilder.ToString().Trim()
    })

    return $oResult
}

function DisplayException($ex) {
    Write-Host $ex | Format-List -Force
}

function Download-PublishProfile([string] $outputPath, [string] $slotName) {

    Get-AzureRmWebAppSlotPublishingProfile -OutputFile $outputPath -ResourceGroupName $resourceGroupName -Name $appServiceName -Slot $slotName | Out-Null

}

function Download-WebsiteFile([string] $websiteFilePath, [string] $outputPath, $publishProfile) {

    $fileUrl = if ($websiteFilePath.StartsWith("/")) {
        $publishProfile.FtpPublishUrl + $websiteFilePath
    } else {
        $publishProfile.FtpPublishUrl + "/" + $websiteFilePath
    }

    Download-File -url $fileUrl -userName $publishProfile.FtpUsername -password $publishProfile.FtpPassword -outputPath $outputPath
}

function Get-AllDefaultParameterValues([string] $parametersXmlPath) {

    $parametersXml = New-Object System.Xml.XmlDocument
    $parametersXml.Load($parametersXmlPath)

    $parameterNodes = $parametersXml.SelectNodes("/parameters/*")

    $paramsWithDefaultValues = @{}
    $parameterNodes.GetEnumerator() | foreach-object {
        if ($_.defaultValue) {
            $paramsWithDefaultValues."$($_.Name)" = $_.defaultValue
        }
        if ($_.value) {
            $paramsWithDefaultValues."$($_.Name)" = $_.value
        }
    }
    return $paramsWithDefaultValues
}

function Get-WDParameterValue([string] $parameterName, [string] $parametersXmlPath, [string] $webConfigPath) {

    $parametersXml = New-Object System.Xml.XmlDocument
    $webConfigXml = New-Object System.Xml.XmlDocument

    $parametersXml.Load($parametersXmlPath)
    $webConfigXml.Load($webConfigPath)

    $parameterNode = $parametersXml.SelectSingleNode("/parameters/parameter[@name='$parameterName']")

    if (!$parameterNode) {
        Write-Warning "No WD parameter named $parameterName was found in parameters.xml file '$parametersXmlPath'"
        return ""
    } else {
        $parameterXpath = $parameterNode.SelectSingleNode("parameterEntry[@kind='XmlFile']/`@match").value
        $parameterValue = $webConfigXml.SelectSingleNode($parameterXpath).value

        return $parameterValue
    }
}

function Get-WebConfigSettingValue([string] $settingName, [string] $webConfigPath) {
    $settingValue
    $webConfigXml = New-Object System.Xml.XmlDocument

    $webConfigXml.Load($webConfigPath)
    $settingNode = Select-Xml -Path $webConfigPath -XPath "//configuration/appSettings/add[@key='$settingName']" | Select-Object -ExpandProperty Node -First 1

    if($settingNode) {
        $settingValue = $settingNode.value
    }

    return $settingValue
}

function Get-SettingValue([string] $settingName, [string] $webConfigPath, [string] $fallbackValue) {
    if ($existingProdAppSettings."$settingName") {
        return $existingProdAppSettings."$settingName"
    }
    $webConfigValue = Get-WebConfigSettingValue $settingName $webConfigPath

    if (![string]::IsNullOrWhitespace($webConfigValue)) {
        $webConfigValue = ($webConfigValue | Out-String).Trim()
        return $webConfigValue
    }
    return $fallbackValue
}

function Set-AppSettings([System.Collections.Hashtable] $settings, [string]$slotName) {

    if ($settings) {
        Set-AzureRmWebAppSlot -AppSettings $settings -Name $appServiceName -ResourceGroupName $resourceGroupName -slot $slotName
   }
}

function Read-ExistingAppSettings([string] $slotName){
    $existingAppSettings = (Get-AzureRmWebAppSlot -Name $appServiceName -ResourceGroupName $resourceGroupName -slot $slotName).SiteConfig.AppSettings

    if ($existingAppSettings) {
        $existingAppSettingsHash = New-Object System.Collections.Hashtable
        $existingAppSettings.GetEnumerator() | ForEach-Object {
            $existingAppSettingsHash."$($_.Name)" = $_.Value
        } | Out-Null
    }

    return $existingAppSettingsHash
}

function Add-Setting([System.Object] $deployAppSettings, $settingName, $settingValue) {
    if ($deployAppSettings) {
        $appSettingsHash = ConvertTo-Hashtable $deployAppSettings
        $appSettingsHash[$settingName]= $settingValue
    } else{
        $appSettingsHash = @{
            $settingName = $settingValue
        }
    }
    return $appSettingsHash
}

function Apply-AppSettings([System.Object] $deployAppSettings, [string] $slotName){
    $existingAppSettings = Read-ExistingAppSettings -slotName $slotName

    if ($deployAppSettings) {
        $appSettingsHash = ConvertTo-Hashtable $deployAppSettings
        Write-Host "`nSetting the following Application Settings: " -ForegroundColor Yellow
        $mergedAppSettings = if ($existingAppSettings) {
            Merge-Hashtables -from $appSettingsHash -to $existingAppSettings
            } else {
            $appSettingsHash
            }
        Write-Host ($mergedAppSettings | Out-String)
        Set-AppSettings -settings $mergedAppSettings -slotName $slotName
    } else {
        Write-Host "`nNo new Application Settings added. Current App Settings set on $appServiceName " -ForegroundColor Yellow
        Write-Host ($existingAppSettings | Out-String)
    }
}

function SwapSlots()
{
    Write-Host "Swapping slot $standbySlotName with $productionSlotName ... " -ForegroundColor Yellow

    Switch-AzureRmWebAppSlot -SourceSlotName $standbySlotName.Trim() -DestinationSlotName $productionSlotName -ResourceGroupName $resourceGroupName -Name $appServiceName

}

function Convert-StringToBoolean([Parameter(ValueFromPipeline = $true)][string] $value) {
    return ($value.ToLowerInvariant() -eq "true")
}

function Read-JsonAsHashtable($filePath) {

    $fileContent = [System.IO.File]::ReadAllText($filePath)
    $psCustomObject = ConvertFrom-Json -InputObject $fileContent
    $hashtable = ConvertTo-Hashtable $psCustomObject

    return $hashtable
}

function ConvertTo-Hashtable($object) {

    $type = $object.GetType()

    if ($type -eq [System.Collections.Hashtable]) {
        return (New-StringHashtableFromPropertyEnumerator ($object.GetEnumerator()))
    } else {

        if ($type -eq [System.Management.Automation.PSCustomObject]) {
            return (New-StringHashtableFromPropertyEnumerator ($object.PSObject.Properties))
        } else {
            throw "Cannot convert object of type $type to [System.Collections.Hashtable]"
        }
    }
}

function Merge-Hashtables([System.Collections.Hashtable] $from, [System.Collections.Hashtable] $to) {

    $result = New-Object System.Collections.Hashtable

    if ($to) {
        $to.GetEnumerator() | ForEach-Object {
            $result."$($_.Name)" = $_.Value
        } | Out-Null
    }

    if ($from) {
        $from.GetEnumerator() | ForEach-Object {
            $result."$($_.Name)" = $_.Value
        } | Out-Null
    }

    return $result
}

function New-StringHashtableFromPropertyEnumerator($propertyEnumerator) {

    $hashtable = New-Object System.Collections.Hashtable

    $propertyEnumerator | ForEach-Object {
        $hashtable."$($_.Name)" = if ($null -ne $_.Value) {
            $_.Value.ToString()
        } else {
            [string]::Empty
        }
    }

    return $hashtable
}

function Remove-ConfigBuilders {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_ | Test-Path -PathType Leaf })]
        [string] $configFilePath
    )
    try {
        $doc = (Select-Xml -Path $configFilePath -XPath / ).Node

        Select-Xml -Xml $doc -XPath "/configuration/configSections/section[@name='configBuilders']" |
            Select-Object -ExpandProperty Node |
            ForEach-Object {
                $_.ParentNode.RemoveChild($_) | Out-Null
            }

        Select-Xml -Xml $doc -XPath "/configuration/configBuilders" |
            Select-Object -ExpandProperty Node |
            ForEach-Object {
                $_.ParentNode.RemoveChild($_) | Out-Null
            }

        Select-Xml -Xml $doc -XPath "/configuration/*/@configBuilders" |
            Select-Object -ExpandProperty Node |
            ForEach-Object {
                $_.OwnerElement.RemoveAttributeNode($_) | Out-Null
            }

        $doc.Save($configFilePath)
    }
    catch {
        Write-Host "Failed to remove configBuilders from file '$configFilePath'"
        DisplayException $_.Exception
    }
}

function Invoke-ExtensionsValidation {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_ | Test-Path -PathType Leaf })]
        [string] $configFilePath
    )

    Write-Host "Validating extensions"
    $validationProcess = Invoke-Executable -exeFile $extensionsValidationToolPath `
                                           -args "--configuration-path `"$configFilePath`""

    Write-Host "Process finished. Exit code: $($validationProcess.ExitCode)"
    Write-ProcessStd $validationProcess

    if($validationProcess.ExitCode -ne 0) {
        Write-Host "Some issues were detected while validating extensions." -ForegroundColor Red
        Exit 1
    }
}

function Write-ProcessStd{
    param (
        [Parameter(Mandatory = $true)]
        [psobject] $process,
        [Parameter(Mandatory = $false)]
        [bool] $verboseMessage = $false        
    )

    if(-not [string]::IsNullOrWhiteSpace($process.StdOut)){
        if($verboseMessage){
            Write-Verbose "StdOut: $($process.StdOut)"
        }else{
            Write-Host "StdOut: $($process.StdOut)"
        }
    }
    
    if(-not [string]::IsNullOrWhiteSpace($process.StdErr)){
        Write-Host "StdErr: $($process.StdErr)" -ForegroundColor Red
    }    
}

Main
