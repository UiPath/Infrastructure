[CmdletBinding()]
Param
(
    [Parameter(Mandatory = $true,
        HelpMessage = "Name of the DNS zone:")]
    [string]$DNSZone,
    [Parameter(Mandatory = $true,
        HelpMessage = "Name of the HAA cluster(Not FQDN):")]
    [string]$HAAClusterName,
    [Parameter(Mandatory = $true,
        HelpMessage = "HAA node ip")]
    [string []]$HAANodeIP
)

    Write-Host "Using DNS zone:"$DNSZone
    Write-Host "Using HAA cluster name:"$HAAClusterName

    for ($i = 1; $i -le $HAANodeIP.Length; $i++) {
        $HAANodeName = Read-Host "Please enter the name of the HAA node (in order of the IP provided earlier): "
        $nodeFQDN = $HAANodeName + ".$DNSZone"
        Add-DnsServerResourceRecordA -Name $HAANodeName -ZoneName $DNSZone -IPv4Address $HAANodeIP -AllowUpdateAny
        Add-DnsServerZoneDelegation -Name $DNSZone -ChildZoneName $HAAClusterName -NameServer $nodeFQDN -IPAddress $HAANodeIP -PassThru
    }



