function Get-UiPathOrchestratorLoginSession {
    param(
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
    $dataLogin = @{
        tenancyName            = $tenant
        usernameOrEmailAddress = $orchAdmin
        password               = $orchPassword
    } | ConvertTo-Json
    
    $orchUrlLogin = "$orchUrl/api/Account/Authenticate"
    
    try {
        $orchWebResponse = Invoke-RestMethod -Uri $orchUrlLogin `
            -Method Post `
            -Body $dataLogin `
            -ContentType "application/json" `
            -UseBasicParsing `
            -SessionVariable websession
    }
    catch {
        Write-Error "Authentication failed with message: $($_.ErrorDetails.Message)"
        Exit 1
    }
    $websession.Headers.Add('Authorization', "Bearer " + $orchWebResponse.result)
    return $websession
}

function Get-OrchTenantUsersByString {
    param(
        [Parameter(Mandatory = $true)]
        [string]$userString,

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

    $websession = Get-UiPathOrchestratorLoginSession -orchUrl $orchUrl `
        -orchAdmin $orchAdmin `
        -orchPassword $orchPassword `
        -tenant $tenant
    
    $orchUsersURL = "$orchUrl/odata/Users"
    
    $robotsUsers = Invoke-RestMethod -Uri "$orchUsersURL`?`$filter=contains(UserName, `'$($userString)`')" `
        -Method Get `
        -UseBasicParsing `
        -WebSession $websession

    return $robotsUsers
}

function Remove-OrchTenantUsersById {
    param(
        [Parameter(Mandatory = $true)]
        [string]$robotId,

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

    $websession = Get-UiPathOrchestratorLoginSession -orchUrl $orchUrl `
        -orchAdmin $orchAdmin `
        -orchPassword $orchPassword `
        -tenant $tenant
    
    $orchUsersURL = "$orchUrl/odata/Users"
    Invoke-RestMethod -Uri "$orchUsersURL($robotId)" `
        -Method Delete `
        -UseBasicParsing `
        -WebSession $websession
}

function Get-OrchTenantMachineTemplatesByString {
    param(
        [Parameter(Mandatory = $true)]
        [string]$machineString,

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

    $websession = Get-UiPathOrchestratorLoginSession -orchUrl $orchUrl `
        -orchAdmin $orchAdmin `
        -orchPassword $orchPassword `
        -tenant $tenant
    
    $orchMachinesURL = "$orchUrl/odata/Machines"
    
    $machineTemplates = Invoke-RestMethod -Uri "$orchMachinesURL`?`$filter=contains(Name, `'$($machineString)`')" `
        -Method GET `
        -ContentType "application/json" `
        -UseBasicParsing `
        -WebSession $websession

    return $machineTemplates
}

function Remove-OrchTenantMachineTemplateById {
    param(
        [Parameter(Mandatory = $true)]
        [string]$machineTemplateId,

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

    $websession = Get-UiPathOrchestratorLoginSession -orchUrl $orchUrl `
        -orchAdmin $orchAdmin `
        -orchPassword $orchPassword `
        -tenant $tenant
    
    $orchUsersURL = "$orchUrl/odata/Machines"
    Invoke-RestMethod -Uri "$orchUsersURL($machineTemplateId)" `
        -Method Delete `
        -UseBasicParsing `
        -WebSession $websession
}

function Remove-ChangePasswordOnFirstLoginPolicy {
    param(

        [Parameter(Mandatory = $true)]
        [ValidateScript( { if (($_ -as [System.URI]).AbsoluteURI -eq $null) { throw "Invalid" } return $true })]
        [string]$orchUrl,

        [Parameter(Mandatory = $true)]
        [string]$orchAdmin,
    
        [Parameter(Mandatory = $true)]
        [string]$orchPassword,
    
        [Parameter(Mandatory = $false)]
        [string]$tenant = "host"
    )

    $websession = Get-UiPathOrchestratorLoginSession -orchUrl $orchUrl `
        -orchAdmin $orchAdmin `
        -orchPassword $orchPassword `
        -tenant $tenant

    $orchSettingsURL = "$orchUrl/odata/Settings"
    $body = @{
        Name = "Auth.Password.ShouldChangePasswordAfterFirstLogin"
        Value = "false"
        Scope = "All"
        Id = "Auth.Password.ShouldChangePasswordAfterFirstLogin"
    } | ConvertTo-Json
    Invoke-RestMethod -Uri "$orchSettingsURL('Auth.Password.ShouldChangePasswordAfterFirstLogin')" `
        -Method Put `
        -ContentType "application/json;odata.metadata=minimal;odata.streaming=true" `
        -UseBasicParsing `
        -WebSession $websession `
        -Body $body
}
