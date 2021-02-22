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
                $azEnvironment = (Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET -Uri "http://169.254.169.254/metadata/instance?api-version=2020-09-01" -TimeoutSec 180).compute.azEnvironment
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
