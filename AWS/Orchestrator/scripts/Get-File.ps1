[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ if (($_ -as [System.URI]).AbsoluteURI -eq $null) {throw "Invalid"} return $true })]
    [string]$Source,

    [Parameter(Mandatory = $true)]
    [string]$Destination
)
    
try {
    $ErrorActionPreference = "Stop"

    $parentDir = Split-Path $Destination -Parent
    if (-not(Test-Path $parentDir)) {
        New-Item -Path $parentDir -ItemType directory -Force | Out-Null
    }

    $Uri = [uri]$Source
    $Scheme = $Uri.Scheme
    if ($Scheme -eq "s3") {
        $tries = 5
        Write-Verbose "Trying to download from bucket $($Uri.Host) key $($Uri.PathAndQuery.Trim(""/""))"
        while ($tries -ge 1) {
            try {
                Read-S3Object -BucketName $Uri.Host -Key $Uri.PathAndQuery.Trim("/") -File $Destination -ErrorAction Stop
                break
            }
            catch {
                $tries--
                Write-Verbose "Exception: $_"
                if ($tries -lt 1) {
                    throw $_
                }
                else {
                    Write-Verbose "Failed download. Retrying again in 1 second"
                    Start-Sleep 1
                }
            }
        }
    }
    elseif ($Scheme -in ("http", "https")) {
        Write-Verbose "Trying to download from $Source"
        $tries = 5
        while ($tries -ge 1) {
            try {
                (New-Object System.Net.WebClient).DownloadFile($Source, $Destination)
                break
            }
            catch {
                $tries--
                Write-Verbose "Exception: $_"
                if ($tries -lt 1) {
                    throw $_
                }
                else {
                    Write-Verbose "Failed download. Retrying again in 1 second"
                    Start-Sleep 1
                }
            }
        }
    }
    else {
        throw "$Source is not a valid S3, HTTP, or HTTPS URI"
    }
}
catch {
    Write-Error -Exception $_.Exception -Message "Failed to download file $Source"
    throw $_.Exception
}
