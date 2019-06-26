[CmdletBinding()]
Param
(
    [Parameter(Mandatory = $true,
        HelpMessage = "Name of the DNS zone:")]
    [string]$DNSZone,
    [Parameter(Mandatory = $true,
        HelpMessage = "Name of the Redis cluster(Not FQDN):")]
    [string]$RedisClusterName,
    [Parameter(Mandatory = $true,
        HelpMessage = "Redis node ip")]
    [string []]$RedisNodeIP
)

    Write-Host "Using DNS zone:"$DNSZone
    Write-Host "Using Redis cluster name:"$RedisClusterName

    for ($i = 1; $i -le $RedisNodeIP.Length; $i++) {
        $redisNodeName = Read-Host "Please enter the name of the Redis node (in order of the IP provided earlier): "
        $nodeFQDN = $redisNodeName + ".$DNSZone"
        Add-DnsServerResourceRecordA -Name $redisNodeName -ZoneName $DNSZone -IPv4Address $RedisNodeIP -AllowUpdateAny
        Add-DnsServerZoneDelegation -Name $DNSZone -ChildZoneName $RedisClusterName -NameServer $nodeFQDN -IPAddress $RedisNodeIP -PassThru
    }



