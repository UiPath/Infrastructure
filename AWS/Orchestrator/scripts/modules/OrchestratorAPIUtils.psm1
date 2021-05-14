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
        Name  = "Auth.Password.ShouldChangePasswordAfterFirstLogin"
        Value = "false"
        Scope = "All"
        Id    = "Auth.Password.ShouldChangePasswordAfterFirstLogin"
    } | ConvertTo-Json
    Invoke-RestMethod -Uri "$orchSettingsURL('Auth.Password.ShouldChangePasswordAfterFirstLogin')" `
        -Method Put `
        -ContentType "application/json;odata.metadata=minimal;odata.streaming=true" `
        -UseBasicParsing `
        -WebSession $websession `
        -Body $body
}
function Get-IdentityInstallationToken {
    param(
        [Parameter(Mandatory = $true)]
        [string]$identityUrl,
        [Parameter(Mandatory = $true)]
        [string]$hostUserName,
        [Parameter(Mandatory = $true)]
        [string]$password
    )
    $antifUrl = $identityUrl + "/api/antiforgery/generate"
    $loginUrl = $identityUrl + "/api/Account/Login"
    $tokenUrl = $identityUrl + "/api/Account/ClientAccessToken"
    
    Invoke-WebRequest -Uri $antifUrl -Method Get -ContentType "application/json" -Session websession -UseBasicParsing | Out-Null
    $websession.Cookies.GetCookies($antifUrl)[1].Name = "XSRF-TOKEN"
    $dataLogin = @{
        tenant          = "host"         
        usernameOrEmail = $hostUserName         
        password        = $password         
        rememberLogin   = $true     
    } | ConvertTo-Json
    $temp = $websession.Cookies.GetCookies($antifUrl)[1].Value
    $websession.Headers.'X-XSRF-TOKEN' = $temp
    Invoke-WebRequest -Uri $loginUrl -Method Post -Body $dataLogin -ContentType "application/json" -WebSession $websession -UseBasicParsing | Out-Null
    $tokenResponse = Invoke-WebRequest -Uri $tokenUrl -Method Get  -ContentType "application/json" -WebSession $websession -UseBasicParsing
    return $tokenResponse.Content
}

function Convert-FileToJson() {
    param(
        [Parameter(Mandatory = $true)]
        [string]$filePath
    )
    $object = Get-Content -Path $filePath | ConvertFrom-Json -AsHashtable -Depth 10
    return $object
}
function Write-JsonToFile() {
    param(
        [Parameter(Mandatory = $true)]
        [string]$filePath,
        [Parameter(Mandatory = $true)]
        [string]$jsonObject
    )
    
    $jsonObject | Out-File -FilePath $filePath
}

function Generate-IdentityTokenAndInsertIntoFile {
    Param (
        [Parameter(Mandatory = $true)]
        [string] $identityUrl,
        [Parameter(Mandatory = $true)]
        [string] $hostUserName,
        [Parameter(Mandatory = $true)]
        [string] $password,
        [Parameter(Mandatory = $true)]
        [string] $parameterFilePath,
        [Parameter(Mandatory = $true)]
        [string] $parameterKey
    )
    $token = Get-IdentityInstallationToken -identityUrl $identityUrl -hostUserName $hostUserName -password $password
    if($token.GetType().Name -ne "String")
    {
        throw "Identity Installation Token was not valid string." 
    }
    if([string]::IsNullOrEmpty($token))
    {
        throw "Identity Installation Token was empty or null string."
    }
    $parameters = Convert-FileToJson -filePath $parameterFilePath
    $parameters[$parameterKey] = @{value = $token }
    $jsonParamters = $parameters | ConvertTo-Json 
    Write-JsonToFile -filePath $parameterFilePath -jsonObject $jsonParamters
    return
}