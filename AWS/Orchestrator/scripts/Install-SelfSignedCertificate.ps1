[CmdletBinding()]
param(
    [string] $rootPath,
    [string] $certificatePassword,
    [string] $orchestratorHost
)
try
{
    $ErrorActionPreference = "Stop"
    if( -not (Test-Path $rootPath\$orchestratorHost.pfx) ) {
        Write-Verbose "Creating self signed certificate"

        $installCert = New-SelfSignedCertificate -Subject "CN=$orchestratorHost" `
            -DnsName "$orchestratorHost" `
            -Type SSLServerAuthentication `
            -KeyExportPolicy Exportable `
            -FriendlyName "Orchestrator Self-Signed SSL Certificate" `
            -HashAlgorithm sha256 -KeyLength 2048 `
            -NotAfter (Get-Date).AddYears(20) `
            -CertStoreLocation "cert:\LocalMachine\My" `
            -KeySpec KeyExchange

        $certThumbprint = $installCert.Thumbprint

        $mypwd = ConvertTo-SecureString -String "$certificatePassword" -Force -AsPlainText
        Export-PfxCertificate -Cert "cert:\LocalMachine\my\$certThumbprint" -FilePath "$rootPath\$orchestratorHost.pfx" -NoProperties -Password $mypwd
        Import-PfxCertificate -FilePath "$rootPath\$orchestratorHost.pfx" -CertStoreLocation Cert:\LocalMachine\Root -Password $mypwd
    } else {
        Write-Verbose "Installing certificate"

        $mypwd = ConvertTo-SecureString -String "$certificatePassword" -Force -AsPlainText
        Import-PfxCertificate -FilePath "$rootPath\$orchestratorHost.pfx" -CertStoreLocation Cert:\LocalMachine\Root -Password $mypwd
        Import-PfxCertificate -FilePath "$rootPath\$orchestratorHost.pfx" -CertStoreLocation cert:\LocalMachine\my -Password $mypwd
    }
} catch {
    Write-Error -Exception $_.Exception -Message "Failed create self signed certificates"
    throw $_.Exception
}
