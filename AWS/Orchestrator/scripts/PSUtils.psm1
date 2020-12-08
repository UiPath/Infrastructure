function Test-URLForOK {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript( { if (($_ -as [System.URI]).AbsoluteURI -eq $null) { throw "Invalid" } return $true })]
        [string]$url,
        [Parameter(Mandatory = $false)]
        [int]$retryCount = 5,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Linear", "Exponential")]
        [string]$retryPolicy = "Linear"
    )

    try {
        $tries = 0
        Write-Host "Getting response from URL: $url"
        while ($tries -le $retryCount) {
            try {
                Invoke-WebRequest -URI $url -Method 'GET' -TimeoutSec 180 -UseBasicParsing
                break
            }
            catch {
                $tries++
                Write-Host "Exception: $_"
                if ($tries -gt $retryCount) {
                    throw $_
                }
                else {
                    if ($retryPolicy -eq "Linear") {
                        Write-Host "Failed to GET $url. Retrying again in 10 seconds"
                        Start-Sleep 10
                    }
                    if ($retryPolicy -eq "Exponential") {
                        Write-Host "Failed to GET $url. Retrying again in $($tries * 10) seconds"
                        Start-Sleep ($tries * 10)
                    }
                }
            }
        }

    }
    catch {
        Write-Error -Exception $_.Exception -Message "Exception occured when doing a HTTP GET at $url"
        throw $_.Exception
    }
}
