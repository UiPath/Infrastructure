
<#
.Description
Remove-OrchArtifacts requires OrchestratorAPIUtils module to be loaded. 
Removes the Orchestrator Users and Machine templates that match the -uniqueString parameter
#>
function Remove-OrchArtifacts {
    param(
        [Parameter(Mandatory = $true)]
        [string]$uniqueString,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { if (($_ -as [System.URI]).AbsoluteURI -eq $null) { throw "Invalid" } return $true })]
        [string]$orchUrl,

        [Parameter(Mandatory = $true)]
        [string]$orchAdmin,
        
        [Parameter(Mandatory = $true)]
        [string]$orchPassword,
        
        [Parameter(Mandatory = $false)]
        [string]$tenant = "Default"
    
    )
    
    $robotsUsernames = Get-OrchTenantUsersByString -userString $uniqueString -orchUrl $orchUrl -orchAdmin $orchAdmin -orchPassword $orchPassword -tenant $tenant

    foreach ($robot in $robotsUsernames.value) {
        Remove-OrchTenantUsersById -robotId $robot.id -orchUrl $orchUrl -orchAdmin $orchAdmin -orchPassword $orchPassword -tenant $tenant
    }

    $robotsMachineTemplates = Get-OrchTenantMachineTemplatesByString -machineString $uniqueString -orchUrl $orchUrl -orchAdmin $orchAdmin -orchPassword $orchPassword -tenant $tenant

    foreach ($machineTemplate in $robotsMachineTemplates.value) {
        Remove-OrchTenantMachineTemplateById -machineTemplateId $machineTemplate.id -orchUrl $orchUrl -orchAdmin $orchAdmin -orchPassword $orchPassword -tenant $tenant
    }
}
