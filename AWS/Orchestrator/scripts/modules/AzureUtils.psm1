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
    if ($sendTelemetryTo) {
        
        $dateTimeNow = (Get-Date -UFormat "%Y-%m-%dT%T%Z00")
        $uri = "https://dc.services.visualstudio.com/v2/track"
        $payload = @{
            name = "AppEvents"
            time = $dateTimeNow
            iKey = $sendTelemetryTo
            # tags = @{
            #     ai.cloud.roleInstance = "AzMarketplaceTelemetry"
            #     ai.internal.sdkVersion = "rest"
            # }
            data = @{
                baseType = "EventData"
                baseData = @{
                    ver        = 2
                    name       = $name
                    properties = $properties
                }
            }
        } | ConvertTo-Json -Depth 10
        Invoke-WebRequest -Method POST -Uri $uri -Body $payload -ContentType "application/json"  -ErrorAction SilentlyContinue -UseBasicParsing
    }

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

function Ensure-SharedImageDefinition {
    
    Param(
        [parameter(Mandatory = $true)]
        [System.Object] $gallery,
        [parameter(Mandatory = $true)]
        [System.Object] $image
    )

    try {
        $existingimageDefinition = Get-AzGalleryImageDefinition -GalleryName $gallery.Name -ResourceGroupName $gallery.ResourceGroupName -Name $gallery.myImageDefinition
    }
    catch{
        if ($_.Exception.Message.Contains("The Resource 'Microsoft.Compute/galleries/$($gallery.Name)/images/$($gallery.myImageDefinition)' under resource group '$($gallery.ResourceGroupName)' was not found")) {
            $newimageDefinition = New-AzGalleryImageDefinition `
                -GalleryName $gallery.Name `
                -ResourceGroupName $gallery.ResourceGroupName `
                -Location $gallery.Location `
                -Name $gallery.myImageDefinition `
                -OsState generalized `
                -OsType $image.OsType `
                -Publisher $image.myPublisher `
                -Offer $image.myOffer `
                -Sku $image.mySKU `
                -HyperVGeneration $image.HyperVGeneration
        
            return $newimageDefinition
        }
        else{
            Write-Error -Exception $_.Exception -Message "Could not ensure image definition"
            throw $_.Exception.Message
        }
    }
    return $existingimageDefinition
}

function Increment-ImageVersion {
    
    Param(
        [parameter(Mandatory = $true)]
        [System.Object] $gallery
    )

    try {
        $existingImageVersions = (Get-AzGalleryImageVersion -GalleryName $gallery.Name -ResourceGroupName $gallery.ResourceGroupName -GalleryImageDefinitionName $gallery.myImageDefinition).Name
        [int]$max = 0
        foreach ($version in $existingImageVersions) {
            [int]$currVers = [int]$version.split(".")[-1]
            if ( $currVers -gt $max) {
                $max = $currVers
            }
        }
        return $max + 1

    }
    catch{
        Write-Error -Exception $_.Exception -Message "Could not increment image version"
        throw $_.Exception.Message
    }
}
