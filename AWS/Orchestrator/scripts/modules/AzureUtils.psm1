<#
.Description
Get-AzCloudEnvironment calls the instance metadata service to determine the environment on which the resource is deployed to.
#>
function Get-AzCloudEnvironment {
    try {
        $tries = 0
        $retryCount = 5
        Write-Host "Getting environment from instance metadata service"
        while ($tries -le $retryCount) {
            try {
                $azEnvironment = (Invoke-RestMethod -Headers @{"Metadata" = "true" } -Method GET -Uri "http://169.254.169.254/metadata/instance?api-version=2020-09-01" -TimeoutSec 180).compute.azEnvironment
                break
            }
            catch {
                $tries++
                Write-Host "Exception: $_"
                if ($tries -gt $retryCount) {
                    throw $_
                }
                else {
                    Write-Host "Failed to reach instance metadata service. Retrying again in $($tries * 10) seconds"
                    Start-Sleep ($tries * 10)
                }
            }
        }
    }
    catch {
        Write-Error -Exception $_.Exception -Message "Instance metadata service is unavailable."
        throw $_.Exception
    }
    
    return $azEnvironment
}

function Send-LogFileToInsights ($insightsKey, $logFile) {
    $TelClient = New-Object "Microsoft.ApplicationInsights.TelemetryClient"
    $TelClient.InstrumentationKey = $insightsKey
    
    foreach ($row in Get-Content $logFile) {
        $TelClient.TrackEvent("[PSConfig] $row")
    }
    $TelClient.Flush()
}

function Send-TelemetryToInsights {

    Param(
        [parameter(Mandatory = $true)]
        [string] $name,
        [parameter(Mandatory = $true)]
        [hashtable] $properties,
        [Parameter(Mandatory = $false)]
        [string] $sendTelemetryTo = ""
    )
    if (([appdomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.FullName -like 'Microsoft.ApplicationInsights*' }).Count -eq 0) {
        Install-TelemetryAssembly
    }
    if (!([string]::IsNullOrEmpty($sendTelemetryTo)) -and 
        (([appdomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.FullName -like 'Microsoft.ApplicationInsights*' }).Count -gt 0)) {
        
        $TelClient = New-Object "Microsoft.ApplicationInsights.TelemetryClient"
        $TelClient.InstrumentationKey = $sendTelemetryTo
        $telemetryEvent = New-Object Microsoft.ApplicationInsights.DataContracts.EventTelemetry
        $telemetryEvent.Name = $name;
    
        foreach ($item in $properties.GetEnumerator()) {
            $telemetryEvent.Properties[$item.Name] = $item.Value
        }
    
        $TelClient.TrackEvent($telemetryEvent)
        $TelClient.Flush()
    }
    else {
        Write-Host "No telemetry was sent."
    }
}

function Install-TelemetryAssembly {
    
    Register-PackageSource -Name TelNuGet -Location "https://www.nuget.org/api/v2" -ProviderName NuGet -Force -ErrorAction SilentlyContinue
    Install-Package Microsoft.ApplicationInsights -Source TelNuGet -Force -SkipDependencies -Destination ./ -RequiredVersion 2.17.0 -ErrorAction SilentlyContinue
    Add-Type -Path "Microsoft.ApplicationInsights.2.17.0\lib\netstandard2.0\Microsoft.ApplicationInsights.dll" -ErrorAction SilentlyContinue
}

function Add-TextBetweenStringsInFile {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$filePath,

        [Parameter(Mandatory = $true)]
        [string]$regexTextStart,

        [Parameter(Mandatory = $true)]
        [string]$regexTextEnd,

        [Parameter(Mandatory = $true)]
        [string]$textToAdd

    )
    
    $regex = "(?<=$regexTextStart)[^$regexTextEnd]*"
    (Get-Content $filePath) -replace $regex, $textToAdd | Set-Content $filePath
}
