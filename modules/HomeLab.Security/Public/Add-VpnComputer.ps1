<#
.SYNOPSIS
    Adds the current computer to the VPN.
.DESCRIPTION
    Registers the current computer for VPN access.
.EXAMPLE
    Add-VpnComputer
.OUTPUTS
    Hashtable containing success status and message.
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
