[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Source,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ if (($_ -as [System.URI]).AbsoluteURI -eq $null) {throw "Invalid"} return $true })]
    [string]$Destination
)

try {
    $ErrorActionPreference = "Stop"

    if (-not(Test-Path $Source -PathType leaf)) {
        Write-Verbose "Did no find a file at path $Source"
        throw "Cannot find file $Source"
    }

    $Uri = [uri]$Destination
    $Scheme = $Uri.Scheme
    if ($Scheme -eq "s3") {
        $tries = 5
        Write-Verbose "Trying to upload file to bucket $($Uri.Host) key $($Uri.PathAndQuery.Trim(""/""))"
        while ($tries -ge 1) {
            try {
                Write-S3Object -BucketName $Uri.Host -Key $Uri.PathAndQuery.Trim("/") -File $Source -ErrorAction Stop
                break
            }
            catch {
                $tries--
                Write-Verbose "Exception: $_"
                if ($tries -lt 1) {
                    throw $_
                }
                else {
                    Write-Verbose "Failed upload. Retrying again in 1 second"
                    Start-Sleep 1
                }
            }
        }
    }
    else {
        throw "$Source is not a valid S3 URI"
    }
}
catch {
    Write-Error -Exception $_.Exception -Message "Failed to upload file $Source"
    throw $_.Exception
}

