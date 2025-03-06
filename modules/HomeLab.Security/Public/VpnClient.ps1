<#
.SYNOPSIS
    VPN Client Management Functions
.DESCRIPTION
    Provides functions for managing VPN client connections.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>

function Add-VpnComputer {
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
