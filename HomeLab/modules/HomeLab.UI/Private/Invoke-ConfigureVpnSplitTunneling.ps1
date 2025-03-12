<#
.SYNOPSIS
    Handles the Configure VPN Split Tunneling menu option.
.DESCRIPTION
    Presents options for configuring VPN split tunneling settings.
.EXAMPLE
    Invoke-ConfigureVpnSplitTunneling
.NOTES
    Author: Jurie Smit
    Date: March 8, 2025
#>
function Invoke-ConfigureVpnSplitTunneling {
    [CmdletBinding()]
    param()
    
    Clear-Host
    Write-Host "===== CONFIGURE VPN SPLIT TUNNELING =====" -ForegroundColor Cyan
    Write-Host
    
    # Get current configuration
    $config = Get-Content -Path "$PSScriptRoot\config.json" | ConvertFrom-Json
    $currentEnabled = if ($config.vpn.enableSplitTunneling -ne $null) { $config.vpn.enableSplitTunneling } else { $false }
    $currentRoutes = if ($config.vpn.splitTunnelingRoutes) { $config.vpn.splitTunnelingRoutes -join ", " } else { "None" }
    
    Write-Host "Current Split Tunneling Configuration:" -ForegroundColor Yellow
    Write-Host "  Enabled: $currentEnabled" -ForegroundColor Yellow
    Write-Host "  Routes: $currentRoutes" -ForegroundColor Yellow
    Write-Host
    
    # Ask to enable or disable
    $enableOption = Read-Host "Enable split tunneling? (Y/N)"
    $enableSplitTunneling = $enableOption.ToUpper() -eq "Y"
    
    $routes = @()
    if ($enableSplitTunneling) {
        Write-Host
        Write-Host "Enter routes to include in split tunneling (leave empty to finish):" -ForegroundColor Cyan
        Write-Host "Example: 10.0.0.0/8" -ForegroundColor Gray
        
        $routeInput = "start"
        while ($routeInput -ne "") {
            $routeInput = Read-Host "Route"
            if ($routeInput -ne "") {
                # Validate route format (basic validation)
                if ($routeInput -match "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d{1,2}$") {
                    $routes += $routeInput
                }
                else {
                    Write-Host "Invalid route format. Please use CIDR notation (e.g., 10.0.0.0/8)" -ForegroundColor Red
                }
            }
        }
    }
    
    # Confirm changes
    Write-Host
    Write-Host "New Split Tunneling Configuration:" -ForegroundColor Yellow
    Write-Host "  Enabled: $enableSplitTunneling" -ForegroundColor Yellow
    Write-Host "  Routes: $($routes -join ", ")" -ForegroundColor Yellow
    
    $confirm = Read-Host "Apply these changes? (Y/N)"
    if ($confirm.ToUpper() -eq "Y") {
        Set-VpnSplitTunneling -Enable $enableSplitTunneling -Routes $routes
    }
    else {
        Write-Host "Changes cancelled." -ForegroundColor Yellow
    }
    
    Write-Host
    Write-Host "Press any key to return to the VPN Gateway Menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}