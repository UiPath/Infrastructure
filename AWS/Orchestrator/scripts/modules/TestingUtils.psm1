<#
.Description
Test-URLForOK calls an url and expects a 200. If it gets a 200 it exists ok, 
if not it will apply the retry policy and throw an error if it still does not get a 200 OK HTTP response.
#>
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
                Invoke-WebRequest -URI $url `
                    -Method 'GET' `
                    -TimeoutSec 180 `
                    -UseBasicParsing
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

<#
.Description
Test-RobotUserIsCreated requires OrchestratorAPIUtils module to be loaded. 
It exists with 0 if the tests are correct and with 1 if not. 
The main check is if the number of robots that match the robotUniqueString parameter that exists in the orchestrator tenant equals with the expectedRobotsWithUniqueString parameter.
#>
function Test-RobotUserIsCreated {
    param(
        [Parameter(Mandatory = $true)]
        [string]$robotUniqueString,

        [Parameter(Mandatory = $true)]
        [string]$expectedRobotsWithUniqueString, #kept string to compare easier since only doing equality (no casting)

        [Parameter(Mandatory = $true)]
        [ValidateScript( { if (($_ -as [System.URI]).AbsoluteURI -eq $null) { throw "Invalid" } return $true })]
        [string]$orchUrl,

        [Parameter(Mandatory = $true)]
        [string]$orchAdmin,
        
        [Parameter(Mandatory = $true)]
        [string]$orchPassword,
        
        [Parameter(Mandatory = $false)]
        [string]$tenant = "Default",

        [Parameter(Mandatory = $false)]
        [int]$retryCount = 5,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Linear", "Exponential")]
        [string]$retryPolicy = "Linear"
        
    )
    try {
        $tries = 0
        while ($tries -le $retryCount) {
            try {
                
                $websession = Get-UiPathOrchestratorLoginSession -orchUrl $orchUrl -orchAdmin $orchAdmin -orchPassword $orchPassword -tenant $tenant
                $orchUsers = "$orchUrl/odata/Users"
                $result = Invoke-RestMethod -Uri "$orchUsers`?`$filter=contains(UserName, `'$($robotUniqueString)`')" -Method Get -UseBasicParsing -WebSession $websession

                if ($result.'@odata.count' -ne $expectedRobotsWithUniqueString) {Exit 1}
                else {return}
            }
            catch {
                $tries++
                Write-Host "Exception: $_"
                if ($tries -gt $retryCount) {
                    throw $_
                }
                else {
                    if ($retryPolicy -eq "Linear") {
                        Write-Host "Failed to GET $orchUrl. Retrying again in 10 seconds"
                        Start-Sleep 10
                    }
                    if ($retryPolicy -eq "Exponential") {
                        Write-Host "Failed to GET $orchUrl. Retrying again in $($tries * 10) seconds"
                        Start-Sleep ($tries * 10)
                    }
                }
            }
        }

    }
    catch {
        Write-Error -Exception $_.Exception -Message "Exception occured when doing a HTTP GET at $orchUrl"
        throw $_.Exception
    }
}
