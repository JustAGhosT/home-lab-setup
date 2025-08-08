<#
.SYNOPSIS
    Formats JSON output from Azure CLI.
.DESCRIPTION
    Formats JSON output from Azure CLI commands for better readability.
.PARAMETER JsonString
    The JSON string to format.
.EXAMPLE
    $formattedJson = Format-AzureCliOutput -JsonString $azureCliOutput
.OUTPUTS
    String. Returns a formatted JSON string.
#>
function Format-AzureCliOutput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$JsonString
    )
    
    try {
        $jsonObject = $JsonString | ConvertFrom-Json
        return $jsonObject | ConvertTo-Json -Depth 10
    }
    catch {
        # If conversion fails, return the original string
        return $JsonString
    }
}