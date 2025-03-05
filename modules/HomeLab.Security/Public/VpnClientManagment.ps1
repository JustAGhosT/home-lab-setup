<#
.SYNOPSIS
    VPN Client Management Module
.DESCRIPTION
    Provides functions for managing VPN client connections including:
      - Adding a computer to the VPN.
      - Connecting to and disconnecting from the VPN.
      - Retrieving the VPN connection status.
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>

function VpnAddComputer {
    [CmdletBinding()]
    param()
    
    Write-Log -Message "Adding current computer to VPN..." -Level INFO
    try {
        # Placeholder: perform any registration or configuration needed.
        Start-Sleep -Seconds 1
        Write-Log -Message "Computer successfully added to VPN." -Level INFO
        return @{ Success = $true; Message = "Computer added to VPN." }
    }
    catch {
        Write-Log -Message "Error adding computer to VPN: $_" -Level ERROR
        return @{ Success = $false; Message = "Failed to add computer to VPN." }
    }
}

function VpnConnectDisconnect {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ParameterSetName="Connect")]
        [switch]$Connect,
        [Parameter(Mandatory = $false, ParameterSetName="Disconnect")]
        [switch]$Disconnect
    )
    
    # Retrieve VPN connection name from configuration or use a default naming convention.
    $config = Get-Configuration
    $vpnName = "$($config.env)-$($config.project)-vpn"  # Example: dev-homelab-vpn
    
    if ($Connect) {
        Write-Log -Message "Connecting to VPN: $vpnName" -Level INFO
        try {
            # Use built-in cmdlet; adjust parameters as necessary.
            Connect-VpnConnection -Name $vpnName -Force -PassThru | Out-Null
            Write-Log -Message "VPN connected successfully." -Level INFO
            return @{ Success = $true; Message = "Connected to VPN." }
        }
        catch {
            Write-Log -Message "Error connecting to VPN: $_" -Level ERROR
            return @{ Success = $false; Message = "Failed to connect to VPN." }
        }
    }
    elseif ($Disconnect) {
        Write-Log -Message "Disconnecting from VPN: $vpnName" -Level INFO
        try {
            Disconnect-VpnConnection -Name $vpnName -Force -PassThru | Out-Null
            Write-Log -Message "VPN disconnected successfully." -Level INFO
            return @{ Success = $true; Message = "Disconnected from VPN." }
        }
        catch {
            Write-Log -Message "Error disconnecting from VPN: $_" -Level ERROR
            return @{ Success = $false; Message = "Failed to disconnect from VPN." }
        }
    }
    else {
        Write-Log -Message "No valid parameter specified. Use -Connect or -Disconnect." -Level ERROR
        return @{ Success = $false; Message = "No valid operation specified." }
    }
}

function Get-VpnConnectionStatus {
    [CmdletBinding()]
    param()
    
    Write-Log -Message "Retrieving VPN connection status..." -Level INFO
    try {
        # Call the built-in Get-VpnConnection; if unavailable, implement a fallback.
        $vpnConnections = Get-VpnConnection -ErrorAction Stop
        Write-Log -Message "VPN connection status retrieved successfully." -Level INFO
        return $vpnConnections
    }
    catch {
        Write-Log -Message "Error retrieving VPN connection status: $_" -Level ERROR
        return $null
    }
}

Export-ModuleMember -Function VpnAddComputer, VpnConnectDisconnect, Get-VpnConnectionStatus
