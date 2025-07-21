# Mock functions for HomeLab integration tests

function Connect-AzAccount {
    return @{
        Context = @{
            Account = @{
                Id = "test@example.com"
            }
            Subscription = @{
                Id = "00000000-0000-0000-0000-000000000000"
                Name = "Test Subscription"
            }
        }
    }
}

function Deploy-Infrastructure {
    param(
        [Parameter()]
        [string]$ResourceGroupName = "test-rg",
        
        [Parameter()]
        [string]$Location = "eastus",
        
        [Parameter()]
        [string]$Component
    )
    
    return @{
        Success = $true
        ResourceGroupName = $ResourceGroupName
        Location = $Location
        Component = $Component
    }
}

function az {
    return '{
        "provisioningState": "Succeeded",
        "name": "test-resource",
        "id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet"
    }'
}