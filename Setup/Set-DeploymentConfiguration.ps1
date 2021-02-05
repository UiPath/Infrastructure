[CmdletBinding()]

param(
    [Parameter()]
    [ValidateSet('Robot', 'Orchestrator')]
    [string] $UiPathSolution
   
)

$filesPath = "./Upload"
$solutionVersionFile = "../Azure/$UiPathSolution/mainTemplate.json"

function Main {
    
    if (!((Test-Path -Path "../Azure/Orchestrator") -and (Test-Path "../Azure/Robot"))) {
        Write-Error "Please run from the setup folder"
        Exit 1
    }

    if (!(Test-Path -Path $solutionVersionFile)) {
        Write-Error "Current solution versions file not found."
        Exit 1
    }

    $mainTemplateParams = (Get-Content $solutionVersionFile | Out-String | ConvertFrom-Json -AsHashtable -Depth 100)["parameters"]
    $solutionVersionKeyName = $mainTemplateParams.Keys | Where-Object { $_ -like "*Version"}
    $uiPathSolutionVersion = $mainTemplateParams[$solutionVersionKeyName].defaultValue

    if (!(Test-Path -Path $filesPath)) {
        New-Item $filesPath -ItemType Directory
    }

    if ($UiPathSolution -eq "Robot") {
        Copy-UiPathRobot -uiPathSolutionVersion $uiPathSolutionVersion
    }
    
    if ($UiPathSolution -eq "Orchestrator") {
        Copy-UiPathOrchestrator -uiPathSolutionVersion $uiPathSolutionVersion
    }
}

function Copy-UiPathRobot {
    Param (
        [Parameter(Mandatory = $true)]
        [String] $uiPathSolutionVersion
    )
    $robotDownloadUri = "https://download.uipath.com/versions/$uiPathSolutionVersion/UiPathStudio.msi"
    Invoke-WebRequest $robotDownloadUri -OutFile "$filesPath\UiPathStudio.msi"
    Write-Output "The UiPath robot file is here: `n$(Resolve-Path $filesPath\UiPathStudio.msi)"
    Write-Output "Please upload to blob storage!"
}

function Copy-UiPathOrchestrator {
    Param (
        [Parameter(Mandatory = $true)]
        [String] $uiPathSolutionVersion
    )
    $orchestratorDownloadUri = "http://download.uipath.com/versions/$uiPathSolutionVersion/UiPathOrchestrator.zip"
    $haaUri = "https://download.uipath.com/haa/2020/2.0/haa-2.0.0.tar.gz"
    Invoke-WebRequest $orchestratorDownloadUri -OutFile "$filesPath\UiPathOrchestrator.zip"
    Invoke-WebRequest $haaUri -OutFile "$filesPath\haa-2.0.0.tar.gz"

    Expand-Archive -LiteralPath "$filesPath\UiPathOrchestrator.zip" -DestinationPath $filesPath -Force

    Remove-Item -Path "$filesPath\UiPathOrchestrator.zip"
    Remove-Item -Path "$filesPath\ps_utils" -Recurse
    Remove-Item -Path "$filesPath\MigrateTo-IdentityServer.ps1"
    Remove-Item -Path "$filesPath\MigrateTo-Webhooks.ps1"
    Remove-Item -Path "$filesPath\Publish-IdentityServer.ps1"
    Remove-Item -Path "$filesPath\Publish-Orchestrator.ps1"
    Remove-Item -Path "$filesPath\UiPathActivities.zip"
    Remove-Item -Path "$filesPath\Publish-Webhooks.ps1"

    Write-Output "Please upload the following files to storage:"
    Write-Output "$(Resolve-Path $filesPath\UiPath.IdentityServer.Migrator.Cli.zip)"
    Write-Output "$(Resolve-Path $filesPath\UiPath.IdentityServer.Web.zip)"
    Write-Output "$(Resolve-Path $filesPath\UiPath.Orchestrator.Web.zip)"
    Write-Output "$(Resolve-Path $filesPath\UiPath.WebhookService.Migrator.Cli.zip)"
    Write-Output "$(Resolve-Path $filesPath\UiPath.WebhookService.Web.zip)"
    Write-Output "$(Resolve-Path $filesPath\haa-2.0.0.tar.gz)"
}

Main
