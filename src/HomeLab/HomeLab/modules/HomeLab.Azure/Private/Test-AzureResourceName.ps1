<#
.SYNOPSIS
    Validates Azure resource names.
.DESCRIPTION
    Checks if a given resource name meets Azure naming requirements.
.PARAMETER ResourceName
    The name of the resource to validate.
.PARAMETER ResourceType
    The type of resource (e.g., "storage", "vm", "vnet").
.EXAMPLE
    Test-AzureResourceName -ResourceName "mystorageaccount" -ResourceType "storage"
.OUTPUTS
    Boolean. Returns $true if the name is valid, $false otherwise.
#>
function Test-AzureResourceName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("storage", "vm", "vnet", "subnet", "natgateway", "vpngateway")]
        [string]$ResourceType
    )
    
    # Define validation rules based on resource type
    switch ($ResourceType) {
        "storage" {
            # Storage account names: 3-24 characters, lowercase letters and numbers only
            return $ResourceName -match "^[a-z0-9]{3,24}$"
        }
        "vm" {
            # VM names: 1-64 characters, alphanumeric, hyphens, and underscores
            return $ResourceName -match "^[a-zA-Z0-9_-]{1,64}$"
        }
        "vnet" {
            # VNet names: 2-64 characters, alphanumeric, hyphens, underscores, and periods
            return $ResourceName -match "^[a-zA-Z0-9_.-]{2,64}$"
        }
        "subnet" {
            # Subnet names: 1-80 characters, alphanumeric, hyphens, underscores, and periods
            return $ResourceName -match "^[a-zA-Z0-9_.-]{1,80}$"
        }
        "natgateway" {
            # NAT Gateway names: 1-80 characters, alphanumeric, hyphens, underscores, and periods
            return $ResourceName -match "^[a-zA-Z0-9_.-]{1,80}$"
        }
        "vpngateway" {
            # VPN Gateway names: 1-80 characters, alphanumeric, hyphens, underscores, and periods
            return $ResourceName -match "^[a-zA-Z0-9_.-]{1,80}$"
        }
        default {
            # Generic validation: 1-90 characters, alphanumeric, hyphens, underscores, and periods
            return $ResourceName -match "^[a-zA-Z0-9_.-]{1,90}$"
        }
    }
}