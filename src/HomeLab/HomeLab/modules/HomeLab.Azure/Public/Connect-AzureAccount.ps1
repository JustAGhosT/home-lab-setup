<#
.SYNOPSIS
    Checks if the user is logged in to Azure and prompts for login if not.
.DESCRIPTION
    Verifies the current Azure login status and attempts to log in if not already logged in.
.EXAMPLE
    if (Connect-AzureAccount) { # Proceed with Azure operations }
.OUTPUTS
    Boolean. Returns $true if logged in successfully, $false otherwise.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Connect-AzureAccount {
    [CmdletBinding()]
    param()

    try {
        $context = az account show 2>$null
        if ($null -eq $context) {
            Write-Log -Message "Not logged in to Azure. Attempting to log in..." -Level Info
            az login | Out-Null
            $context = az account show 2>$null
            if ($null -ne $context) {
                Write-Log -Message "Azure login successful." -Level Success
                return $true
            }
            else {
                Write-Log -Message "Azure login failed." -Level Error
                return $false
            }
        }
        else {
            Write-Log -Message "Already logged in to Azure." -Level Info
            return $true
        }
    }
    catch {
        Write-Log -Message "Error checking Azure login status: $_" -Level Error
        return $false
    }
}
