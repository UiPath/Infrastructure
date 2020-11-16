[CmdletBinding()]

param(

    [Parameter(Mandatory = $true, ParameterSetName = 'Lock')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Release')]
    [switch][bool] $Lock,

    [Parameter(Mandatory = $false, ParameterSetName = 'Lock')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Release')]
    [switch][bool] $Release,

    [Parameter(Mandatory = $true)]
    [string] $TableName
)

try {
    $ErrorActionPreference = "Stop"

    Add-Type -Path (${env:ProgramFiles(x86)} + "\AWS Tools\PowerShell\AWSPowerShell\AWSSDK.DynamoDBv2.dll")

    $client = New-Object -TypeName Amazon.DynamoDBv2.AmazonDynamoDBClient
    $table = [Amazon.DynamoDBv2.DocumentModel.Table]::LoadTable($client, $TableName)

    $key = 'Installation'
    $value = '1'

    $json = ConvertTo-Json -Compress -InputObject @{$key = $value }

    $document = [Amazon.DynamoDBv2.DocumentModel.Document]::FromJson($json)

    if ($Lock) {
        Write-Verbose "Obtaining lock on table $TableName"
        $expression = New-Object -TypeName Amazon.DynamoDBv2.DocumentModel.Expression
        $expression.ExpressionStatement = "attribute_not_exists ($key)"

        $putItemConfig = New-Object -TypeName Amazon.DynamoDBv2.DocumentModel.PutItemOperationConfig
        $putItemConfig.ConditionalExpression = $expression
        $tries = 60
        $errors = 0
        while ($tries -ge 1) {
            try {
                $table.PutItem($document, $putItemConfig)
                break
            }
            catch {
                if ($_.FullyQualifiedErrorId -ne "ConditionalCheckFailedException") {
                    $errors += 1
                    if ($errors -gt 5) {
                        throw
                    }
                }
                $tries--
                Write-Verbose "$_"
                if ($tries -lt 1) {
                    throw $_
                }
                else {
                    Write-Verbose "Failed to acquire lock, retrying again in 30 seconds"
                    Start-Sleep 30
                }
            }
        }
    }
    elseif ($Release) {
        Write-Verbose "Releasing lock on table $TableName"
        $tries = 5
        while ($tries -ge 1) {
            try {
                $table.DeleteItem($document)
                break
            }
            catch {
                $tries--
                Write-Verbose "$_"
                if ($tries -lt 1) {
                    throw $_
                }
                else {
                    Write-Verbose "Failed to release lock, retrying again in 30 seconds"
                    Start-Sleep 30
                }
            }
        }

    }

}
catch {
    Write-Error -Exception $_.Exception -Message "Failed to set lock"
    throw $_.Exception
}
