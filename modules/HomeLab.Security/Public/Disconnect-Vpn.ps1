<#
.SYNOPSIS
    Disconnects from a VPN.
.DESCRIPTION
    Disconnects from a specified VPN connection or uses a default name from configuration.
.PARAMETER ConnectionName
    Optional name of the VPN connection. If not provided, it will be constructed from configuration.
.EXAMPLE
    Disconnect-Vpn
.EXAMPLE
    Disconnect-Vpn -ConnectionName "MyVPN"
.OUTPUTS
    Hashtable containing success status, message, and operation result.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Disconnect-Vpn {
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
    
    Write-Log -Message "Disconnecting from VPN: $ConnectionName" -Level INFO
    try {
        $result = Disconnect-VpnConnection -Name $ConnectionName -Force -PassThru
        
        if ($result) {
            Write-Log -Message "VPN disconnected successfully." -Level INFO
            return @{ Success = $true; Message = "Disconnected from VPN."; Status = $result }
        } else {
            Write-Log -Message "VPN disconnect attempt failed." -Level WARNING
            return @{ Success = $false; Message = "Failed to disconnect from VPN." }
        }
    }
    catch {
        Write-Log -Message "Error disconnecting from VPN: $_" -Level ERROR
        return @{ Success = $false; Message = "Failed to disconnect from VPN: $_"; Error = $_ }
    }
}
