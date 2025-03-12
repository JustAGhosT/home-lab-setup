<#
.SYNOPSIS
    Gets the status of VPN connections.
.DESCRIPTION
    Retrieves the status of all VPN connections or a specific connection.
.PARAMETER ConnectionName
    Optional name of a specific VPN connection to check.
.EXAMPLE
    Get-VpnConnectionStatus
.EXAMPLE
    Get-VpnConnectionStatus -ConnectionName "MyVPN"
.OUTPUTS
    VPN connection objects with status information.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Get-VpnConnectionStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConnectionName
    )
    
    Write-Log -Message "Retrieving VPN connection status..." -Level INFO
    try {
        # If connection name is provided, filter the results
        if ($ConnectionName) {
            $vpnConnections = Get-VpnConnection -Name $ConnectionName -ErrorAction Stop
            Write-Log -Message "VPN connection status for '$ConnectionName' retrieved successfully." -Level INFO
        } else {
            # Get all VPN connections
            $vpnConnections = Get-VpnConnection -ErrorAction Stop
            Write-Log -Message "All VPN connection statuses retrieved successfully." -Level INFO
        }
        
        return $vpnConnections
    }
    catch {
        Write-Log -Message "Error retrieving VPN connection status: $_" -Level ERROR
        return $null
    }
}
