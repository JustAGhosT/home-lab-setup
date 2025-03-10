<#
.SYNOPSIS
    Checks and establishes Azure connection
.DESCRIPTION
    Checks if already connected to Azure and offers to connect if not
.NOTES
    Author: Jurie Smit
    Version: 1.0.0
    Date: March 10, 2025
#>

function Get-AzureConnection {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log -Message "Checking Azure connection" -Level "Info"
        
        # Check if Az module is loaded
        if (-not (Get-Module -Name Az.Accounts)) {
            Write-Log -Message "Az.Accounts module not loaded. Attempting to load..." -Level "Warning"
            Import-Module -Name Az.Accounts -ErrorAction Stop
        }
        
        # Check if already connected
        $context = Get-AzContext -ErrorAction SilentlyContinue
        if ($context -and $context.Account) {
            $script:State.AzContext = $context
            $script:State.User = $context.Account.Id
            $script:State.ConnectionStatus = "Connected"
            
            Write-Log -Message "Already connected to Azure as $($context.Account.Id)" -Level "Success"
            Write-Log -Message "Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))" -Level "Info"
            
            return $true
        }
        else {
            Write-Log -Message "Not connected to Azure" -Level "Warning"
            
            # Ask if user wants to connect
            $connect = Read-Host "You are not connected to Azure. Connect now? (Y/N)"
            if ($connect -eq "Y" -or $connect -eq "y") {
                # Connect to Azure
                $context = Connect-AzAccount -ErrorAction Stop
                
                if ($context) {
                    $script:State.AzContext = $context
                    $script:State.User = $context.Context.Account.Id
                    $script:State.ConnectionStatus = "Connected"
                    
                    Write-Log -Message "Successfully connected to Azure as $($context.Context.Account.Id)" -Level "Success"
                    Write-Log -Message "Subscription: $($context.Context.Subscription.Name) ($($context.Context.Subscription.Id))" -Level "Info"
                    
                    return $true
                }
            }
            else {
                Write-Log -Message "User chose not to connect to Azure" -Level "Warning"
                return $false
            }
        }
    }
    catch {
        Write-Log -Message "Failed to connect to Azure: $_" -Level "Error"
        return $false
    }
    
    return $false
}

# Export the function
Export-ModuleMember -Function Get-AzureConnection
