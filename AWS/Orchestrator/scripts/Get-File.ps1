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
    Add-Type -Path (${env:ProgramFiles(x86)} + "\AWS SDK for .NET\bin\Net45\AWSSDK.S3.dll")

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
                
                Write-Verbose "Gettting $($Uri.PathAndQuery.Trim(""/"")) try: $tries"
                $s3Client = New-Object -TypeName Amazon.S3.AmazonS3Client
                $s3Obj = $s3Client.GetObject($Uri.Host, $Uri.PathAndQuery.Trim("/"))
                $s3Obj.WriteResponseStreamToFile($Destination)
                break
            }
            catch {
                $tries--
                Write-Verbose "Exception: $_"
                if ($tries -lt 1) {
                    throw $_
                }
                else {
                    Write-Verbose "Failed download. Retrying again in 3 second"
                    Start-Sleep 3
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
