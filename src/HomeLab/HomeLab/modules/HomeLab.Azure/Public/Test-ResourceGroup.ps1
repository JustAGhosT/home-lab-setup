<#
.SYNOPSIS
    Tests if a resource group exists.
.DESCRIPTION
    Checks if the specified resource group exists in the current Azure subscription.
.PARAMETER ResourceGroupName
    The name of the resource group to check.
.EXAMPLE
    if (Test-ResourceGroup -ResourceGroupName "my-resource-group") { # Resource group exists }
.OUTPUTS
    Boolean. Returns $true if the resource group exists, $false otherwise.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Test-ResourceGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName
    )
    
    try {
        $rg = az group show --name $ResourceGroupName 2>$null
        if ($null -ne $rg) {
            Write-Log -Message "Resource group '$ResourceGroupName' exists." -Level Info
            return $true
        }
        else {
            Write-Log -Message "Resource group '$ResourceGroupName' does not exist." -Level Warning
            return $false
        }
    }
    catch {
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log -Message "Error testing resource group: $_" -Level Error
        }
        else {
            Write-Host "Error testing resource group: $_" -ForegroundColor Red
        }
        return $false
    }
}
