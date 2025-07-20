# Mock functions for HomeLab.Azure module

function New-AzureResourceGroup {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string]$Location,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Tags
    )
    
    return @{
        ResourceGroupName = $ResourceGroupName
        Location = $Location
        Tags = $Tags
        ProvisioningState = "Succeeded"
    }
}

function Enable-VpnGateway {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$State
    )
    
    return @{
        Name = $Name
        ResourceGroupName = $ResourceGroupName
        State = $State
        ProvisioningState = "Succeeded"
    }
}

function Disable-VpnGateway {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$State
    )
    
    return @{
        Name = $Name
        ResourceGroupName = $ResourceGroupName
        State = $State
        ProvisioningState = "Succeeded"
    }
}

function Get-VpnGatewayState {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    return @{
        Name = $Name
        ResourceGroupName = $ResourceGroupName
        State = "Enabled"
        ProvisioningState = "Succeeded"
    }
}

function Enable-NatGateway {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    return @{
        Name = $Name
        ResourceGroupName = $ResourceGroupName
        State = "Enabled"
        ProvisioningState = "Succeeded"
    }
}

function Disable-NatGateway {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    return @{
        Name = $Name
        ResourceGroupName = $ResourceGroupName
        State = "Disabled"
        ProvisioningState = "Succeeded"
    }
}

function Test-ResourceGroupExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName
    )
    
    # For testing, return true only for specific test cases
    if ($ResourceGroupName -eq "existing-rg") {
        return $true
    }
    
    return $false
}

function Test-ResourceNameFormat {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceType
    )
    
    # Simple validation - name should be alphanumeric with hyphens
    return $Name -match "^[a-zA-Z0-9\-]+$"
}

# No need to export functions in a dot-sourced script