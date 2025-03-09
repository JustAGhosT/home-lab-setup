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
