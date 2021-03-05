[CmdletBinding()]

$features = @(
    'IIS-DefaultDocument',
    'IIS-HttpErrors',
    'IIS-StaticContent',
    'IIS-RequestFiltering',
    'IIS-URLAuthorization',
    'IIS-ApplicationInit',
    'IIS-WindowsAuthentication',
    'IIS-NetFxExtensibility45',
    'IIS-ASPNET45',
    'IIS-ISAPIExtensions',
    'IIS-ISAPIFilter',
    'IIS-WebSockets',
    'IIS-ManagementConsole',
    'ClientForNFS-Infrastructure'
)

$ErrorActionPreference = "Stop"

foreach ($feature in $features) {

    try {
        $state = (Get-WindowsOptionalFeature -FeatureName $feature -Online).State
        Write-Verbose "Feature $feature has state Enabled/Disabled => $state"
        if ($state -ne 'Enabled') {
            Write-Verbose "Installing feature $feature"
            Enable-WindowsOptionalFeature -Online -FeatureName $feature -all -NoRestart
        }
    }
    catch {
        Write-Error -Exception $_.Exception -Message "Failed to install feature $feature"
        throw $_.Exception
    }
    
}

