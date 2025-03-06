<#
.SYNOPSIS
    Helper functions for Azure operations.
.DESCRIPTION
    Contains helper functions for Azure operations, such as connecting to Azure,
    testing if a resource group exists, and resetting a resource group.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>

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
        Write-Log -Message "Error testing resource group: $_" -Level Error
        return $false
    }
}

<#
.SYNOPSIS
    Deletes and recreates a resource group.
.DESCRIPTION
    Deletes the specified resource group if it exists, then recreates it.
    Prompts for confirmation before deletion.
.PARAMETER ResourceGroupName
    The name of the resource group to reset.
.PARAMETER Location
    Optional. The location for the new resource group. If not provided, it will be retrieved from the configuration.
.PARAMETER Force
    Optional. If specified, skips the confirmation prompt.
.EXAMPLE
    Reset-ResourceGroup -ResourceGroupName "my-resource-group" -Location "westeurope" -Force
.OUTPUTS
    Boolean. Returns $true if the resource group was reset successfully, $false otherwise.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Reset-ResourceGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory = $false)]
        [string]$Location,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Check if resource group exists
    $exists = Test-ResourceGroup -ResourceGroupName $ResourceGroupName
    if (-not $exists) {
        Write-Log -Message "Resource group '$ResourceGroupName' does not exist. Creating it..." -Level Info
        
        # Get location from configuration if not provided
        if (-not $Location) {
            $config = Get-Configuration
            $Location = $config.location
            if (-not $Location) {
                $Location = "southafricanorth"  # Default location
            }
        }
        
        # Create the resource group
        az group create --name $ResourceGroupName --location $Location | Out-Null
        Write-Log -Message "Resource group '$ResourceGroupName' created successfully." -Level Success
        return $true
    }
    
    # Prompt for confirmation if Force is not specified
    $proceed = $Force
    if (-not $Force) {
        $proceed = $Host.UI.PromptForChoice(
            "Confirm",
            "Resource group '$ResourceGroupName' already exists. Do you want to delete and recreate it?",
            @("&Yes", "&No"),
            1  # Default is No
        ) -eq 0
    }
    
    if ($proceed) {
        Write-Log -Message "Deleting resource group '$ResourceGroupName'..." -Level Info
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
            Write-Log -Message "Timed out waiting for resource group deletion." -Level Error
            return $false
        }
        
        # Get location from configuration if not provided
        if (-not $Location) {
            $config = Get-Configuration
            $Location = $config.location
            if (-not $Location) {
                $Location = "southafricanorth"  # Default location
            }
        }
        
        Write-Log -Message "Creating resource group '$ResourceGroupName' in location '$Location'..." -Level Info
        az group create --name $ResourceGroupName --location $Location | Out-Null
        Write-Log -Message "Resource group '$ResourceGroupName' recreated successfully." -Level Success
        return $true
    }
    
    Write-Log -Message "Resource group reset cancelled." -Level Info
    return $false
}
