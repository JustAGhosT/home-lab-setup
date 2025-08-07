function Test-AzureConnection {
    <#
    .SYNOPSIS
        Tests if there is an active Azure connection and subscription context.
    
    .DESCRIPTION
        This function verifies that the user is authenticated to Azure and has an active
        subscription context. It checks for both authentication and subscription availability.
    
    .PARAMETER SubscriptionId
        Optional subscription ID to verify. If not provided, checks for any active subscription.
    
    .PARAMETER ThrowOnFailure
        Whether to throw an exception on failure instead of returning false.
        Default is false.
    
    .EXAMPLE
        Test-AzureConnection
        # Returns $true if connected, $false otherwise
    
    .EXAMPLE
        Test-AzureConnection -SubscriptionId "00000000-0000-0000-0000-000000000000" -ThrowOnFailure
        # Throws exception if not connected or subscription not found
    
    .OUTPUTS
        Returns $true if Azure connection is active, $false otherwise.
        Throws exception if ThrowOnFailure is $true and connection fails.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$SubscriptionId,
        
        [Parameter()]
        [switch]$ThrowOnFailure
    )
    
    try {
        # Check if Az.Accounts module is available
        if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
            $errorMessage = "Azure PowerShell module (Az.Accounts) is not installed. Please install it using: Install-Module -Name Az.Accounts -Force"
            if ($ThrowOnFailure) {
                throw $errorMessage
            }
            Write-Warning $errorMessage
            return $false
        }
        
        # Import the module if not already imported
        if (-not (Get-Module -Name Az.Accounts)) {
            Import-Module Az.Accounts -ErrorAction Stop
        }
        
        # Check for active Azure context
        $context = Get-AzContext -ErrorAction SilentlyContinue
        if (-not $context) {
            $errorMessage = "No active Azure context found. Please run Connect-AzAccount to authenticate."
            if ($ThrowOnFailure) {
                throw $errorMessage
            }
            Write-Warning $errorMessage
            return $false
        }
        
        # Check if user is authenticated
        if (-not $context.Account) {
            $errorMessage = "Azure authentication failed. Please run Connect-AzAccount to authenticate."
            if ($ThrowOnFailure) {
                throw $errorMessage
            }
            Write-Warning $errorMessage
            return $false
        }
        
        # Check subscription if specified
        if ($SubscriptionId) {
            if ($context.Subscription.Id -ne $SubscriptionId) {
                # Try to set the specified subscription
                try {
                    $targetContext = Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
                    Write-Verbose "Successfully switched to subscription: $($targetContext.Subscription.Name) ($SubscriptionId)"
                }
                catch {
                    $errorMessage = "Failed to set subscription context to '$SubscriptionId'. Available subscriptions: $($context.Subscription.Name) ($($context.Subscription.Id))"
                    if ($ThrowOnFailure) {
                        throw $errorMessage
                    }
                    Write-Warning $errorMessage
                    return $false
                }
            }
        }
        
        # Verify subscription is accessible
        try {
            $subscription = Get-AzSubscription -ErrorAction Stop
            if (-not $subscription) {
                $errorMessage = "No accessible subscriptions found. Please check your Azure permissions."
                if ($ThrowOnFailure) {
                    throw $errorMessage
                }
                Write-Warning $errorMessage
                return $false
            }
        }
        catch {
            $errorMessage = "Failed to access Azure subscription: $($_.Exception.Message)"
            if ($ThrowOnFailure) {
                throw $errorMessage
            }
            Write-Warning $errorMessage
            return $false
        }
        
        Write-Verbose "Azure connection verified successfully. Account: $($context.Account.Id), Subscription: $($context.Subscription.Name)"
        return $true
    }
    catch {
        $errorMessage = "Azure connection test failed: $($_.Exception.Message)"
        if ($ThrowOnFailure) {
            throw $errorMessage
        }
        Write-Warning $errorMessage
        return $false
    }
} 