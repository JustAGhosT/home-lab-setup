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

# Helper function to set subscription context with error handling
function Set-SubscriptionContext {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$CurrentContext
    )

    try {
        Write-Log -Message "Setting subscription context to $SubscriptionId" -Level "Info"
        $newContext = Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
        Write-Log -Message "Successfully set subscription context to $SubscriptionId" -Level "Success"
        return $newContext
    }
    catch {
        Write-Log -Message "Failed to set subscription context to $SubscriptionId`: $($_.Exception.Message)" -Level "Error"
        return $null
    }
}

function Get-AzureConnection {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter()]
        [string]$SubscriptionId
    )

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
            # If SubscriptionId is provided, set the context to that subscription
            if ($SubscriptionId) {
                $context = Set-SubscriptionContext -SubscriptionId $SubscriptionId -CurrentContext $context
                if (-not $context) {
                    return $false
                }
            }

            # Normalize context object - handle both direct context and nested context structures
            $normalizedContext = if ($context.Context) { $context.Context } else { $context }

            $script:State.AzContext = $normalizedContext
            $script:State.User = $normalizedContext.Account.Id
            $script:State.ConnectionStatus = "Connected"

            Write-Log -Message "Already connected to Azure as $($normalizedContext.Account.Id)" -Level "Success"
            Write-Log -Message "Subscription: $($normalizedContext.Subscription.Name) ($($normalizedContext.Subscription.Id))" -Level "Info"

            return $true
        }
        else {
            Write-Log -Message "Not connected to Azure" -Level "Warning"

            # Ask if user wants to connect with proper validation
            do {
                $connect = Read-Host "You are not connected to Azure. Connect now? (Y/N)"
                $connect = $connect.Trim().ToUpper()
            } while ($connect -notin @('Y', 'N', 'YES', 'NO'))

            if ($connect -in @('Y', 'YES')) {
                # Connect to Azure
                $context = Connect-AzAccount -ErrorAction Stop

                if ($context) {
                    # If SubscriptionId is provided, set the context to that subscription
                    if ($SubscriptionId) {
                        $context = Set-SubscriptionContext -SubscriptionId $SubscriptionId -CurrentContext $context
                        if (-not $context) {
                            return $false
                        }
                    }

                    # Normalize context object - handle both direct context and nested context structures
                    $normalizedContext = if ($context.Context) { $context.Context } else { $context }

                    $script:State.AzContext = $normalizedContext
                    $script:State.User = $normalizedContext.Account.Id
                    $script:State.ConnectionStatus = "Connected"

                    Write-Log -Message "Successfully connected to Azure as $($normalizedContext.Account.Id)" -Level "Success"
                    Write-Log -Message "Subscription: $($normalizedContext.Subscription.Name) ($($normalizedContext.Subscription.Id))" -Level "Info"

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
