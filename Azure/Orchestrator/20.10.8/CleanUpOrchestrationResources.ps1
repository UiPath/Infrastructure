[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String] $RGName,

    [Parameter(Mandatory = $true)]
    [String] $StorageAccountName,
    
    [Parameter(Mandatory = $true)]
    [String] $NICName,

    [Parameter(Mandatory = $true)]
    [String] $VnetName,

    [Parameter(Mandatory = $true)]
    [String] $NSGName,

    [Parameter(Mandatory = $true)]
    [String] $VMName,
    
    [Parameter(Mandatory = $false)]
    [String] $InsightsKey

)
$ErrorActionPreference = "Stop"

$logFile = "Installation.log"
Start-Transcript -Path $logFile -Append -IncludeInvocationHeader

Write-Output "$(Get-Date) Importing custom modules..."
Import-Module ([System.IO.Path]::GetFullPath((Join-Path (Get-Location) "./AzureUtils.psm1"))) -Global -Force

Write-Output " ******* $(Get-Date) Orchestrator installation cleanup started *******"

$vm = Get-AzVm -Name $VMName

$count = 1
while (!$vm.StorageProfile.OSDisk.Name -and ($count -lt 30)) {
    Start-Sleep -Seconds 3
    Write-Host "The value of the disk name is: $($vm.StorageProfile.OSDisk.Name)"
    $count++
}

$OSDiskName = $vm.StorageProfile.OSDisk.Name

Remove-AzVM -Name $VMName -ResourceGroupName $RGName -Force
Remove-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $RGName -Force
Remove-AzNetworkInterface -Name $NICName -ResourceGroupName $RGName -Force
Remove-AzVirtualNetwork -Name $VnetName -ResourceGroupName $RGName -Force
Remove-AzNetworkSecurityGroup -Name $NSGName -ResourceGroupName $RGName -Force
Remove-AzDisk -ResourceGroupName $RGName -DiskName $OSDiskName -Force

Write-Output " ******* $(Get-Date) Orchestrator installation cleanup finished *******"
Stop-Transcript

Send-LogFileToInsights -insightsKey $insightsKey -logFile $logFile
