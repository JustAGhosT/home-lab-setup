<#
.SYNOPSIS
    Connects to a VPN.
.DESCRIPTION
    Connects to a specified VPN connection or uses a default name from configuration.
.PARAMETER ConnectionName
    Optional name of the VPN connection. If not provided, it will be constructed from configuration.
.EXAMPLE
    Connect-Vpn
.EXAMPLE
    Connect-Vpn -ConnectionName "MyVPN"
.OUTPUTS
    Hashtable containing success status, message, and connection status.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Connect-Vpn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConnectionName
    )
    
    # Retrieve VPN connection name from configuration if not provided
    if (-not $ConnectionName) {
        $config = Get-Configuration
        $ConnectionName = "$($config.env)-$($config.project)-vpn"  # Example: dev-homelab-vpn
    }
    
    Write-Log -Message "Connecting to VPN: $ConnectionName" -Level INFO
    try {
        # Use built-in cmdlet; adjust parameters as necessary.
        $result = Connect-VpnConnection -Name $ConnectionName -Force -PassThru
        
        if ($result.ConnectionStatus -eq 'Connected') {
            Write-Log -Message "VPN connected successfully." -Level INFO
            return @{ Success = $true; Message = "Connected to VPN."; Status = $result }
        } else {
            Write-Log -Message "VPN connection attempt completed but status is: $($result.ConnectionStatus)" -Level WARNING
            return @{ Success = $false; Message = "VPN connection attempt completed but not connected."; Status = $result }
        }
    }
    catch {
        Write-Log -Message "Error connecting to VPN: $_" -Level ERROR
        return @{ Success = $false; Message = "Failed to connect to VPN: $_"; Error = $_ }
    }
}
