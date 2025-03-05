<#
.SYNOPSIS
    Helper functions for HomeLab deployment.
.DESCRIPTION
    Contains helper functions used by the deployment process, such as:
      - Connect-AzureAccount: Checks and prompts for Azure login.
      - Test-ResourceGroup: Checks if a resource group exists.
      - Reset-ResourceGroup: Optionally deletes and recreates a resource group.
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>

function Connect-AzureAccount {
    [CmdletBinding()]
    param()

    try {
        $context = az account show 2>$null
        if ($null -eq $context) {
            Write-Log -Message "Not logged in to Azure. Attempting to log in..." -Level INFO
            az login | Out-Null
            $context = az account show 2>$null
            if ($null -ne $context) {
                Write-Log -Message "Azure login successful." -Level SUCCESS
                return $true
            }
            else {
                Write-Log -Message "Azure login failed." -Level ERROR
                return $false
            }
        }
        else {
            Write-Log -Message "Already logged in to Azure." -Level INFO
            return $true
        }
    }
    catch {
        Write-Log -Message "Error checking Azure login status: $_" -Level ERROR
        return $false
    }
}

function Test-ResourceGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName
    )
    
    try {
        $rg = az group show --name $ResourceGroupName 2>$null
        if ($null -ne $rg) {
            Write-Log -Message "Resource group '$ResourceGroupName' exists." -Level INFO
            return $true
        }
        else {
            Write-Log -Message "Resource group '$ResourceGroupName' does not exist." -Level WARNING
            return $false
        }
    }
    catch {
        Write-Log -Message "Error testing resource group: $_" -Level ERROR
        return $false
    }
}

function Reset-ResourceGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName
    )
    
    # Use Get-UserConfirmation from your UI module (assumed to be imported)
    $confirm = Get-UserConfirmation -Message "Resource group '$ResourceGroupName' already exists. Do you want to delete and recreate it?"
    if ($confirm) {
        Write-Log -Message "Deleting resource group '$ResourceGroupName'..." -Level INFO
        az group delete --name $ResourceGroupName --yes --no-wait
        
        # Wait for deletion to complete (simple polling mechanism)
        $deleted = $false
        $timeout = 300  # 5 minutes timeout
        $timer = [Diagnostics.Stopwatch]::StartNew()
        while (-not $deleted -and $timer.Elapsed.TotalSeconds -lt $timeout) {
            Start-Sleep -Seconds 10
            $exists = Test-ResourceGroup -ResourceGroupName $ResourceGroupName
            $deleted = -not $exists
        }
        
        if (-not $deleted) {
            Write-Log -Message "Timed out waiting for resource group deletion." -Level ERROR
            return $false
        }
        
        # Optionally, retrieve the location from configuration or use a default.
        $location = (az account show --query location -o tsv 2>$null) 
        if (-not $location) { $location = "southafricanorth" }
        
        Write-Log -Message "Creating resource group '$ResourceGroupName' in location '$location'..." -Level INFO
        az group create --name $ResourceGroupName --location $location | Out-Null
        Write-Log -Message "Resource group '$ResourceGroupName' recreated successfully." -Level SUCCESS
        return $true
    }
    
    return $false
}

Export-ModuleMember -Function Connect-AzureAccount, Test-ResourceGroup, Reset-ResourceGroup
