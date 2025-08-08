<#
.SYNOPSIS
    Configures split tunneling for the VPN client configuration.
.DESCRIPTION
    Modifies the VPN client configuration to enable or disable split tunneling.
    When enabled, only traffic destined for the specified routes will go through the VPN tunnel.
.PARAMETER Enable
    If true, enables split tunneling. If false, disables split tunneling.
.PARAMETER Routes
    Array of routes to be included in the split tunnel configuration.
.EXAMPLE
    Set-VpnSplitTunneling -Enable $true -Routes @("10.0.0.0/8", "172.16.0.0/12")
.NOTES
    Author: Jurie Smit
    Date: March 8, 2025
#>
function Set-VpnSplitTunneling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Enable,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Routes
    )

    try {
        # Get configuration
        $config = Get-Content -Path "$PSScriptRoot\config.json" | ConvertFrom-Json
        
        # Update VPN configuration
        if (-not (Get-Member -InputObject $config -Name "vpn" -MemberType NoteProperty)) {
            $config | Add-Member -MemberType NoteProperty -Name "vpn" -Value @{}
        }
        
        $vpnConfig = $config.vpn
        $vpnConfig | Add-Member -MemberType NoteProperty -Name "enableSplitTunneling" -Value $Enable -Force
        
        if ($Enable -and $Routes) {
            $vpnConfig | Add-Member -MemberType NoteProperty -Name "splitTunnelingRoutes" -Value $Routes -Force
        }
        
        # Save configuration
        $config | ConvertTo-Json -Depth 10 | Set-Content -Path "$PSScriptRoot\config.json"
        
        # Download current VPN client configuration
        $ResourceGroupName = "$($config.env)-$($config.loc)-rg-$($config.project)"
        $GatewayName = "$($config.env)-$($config.loc)-vpng-$($config.project)"
        $ProfilePath = "$PSScriptRoot\VpnClientProfile.zip"
        
        Write-Host "Downloading VPN client configuration..." -ForegroundColor Yellow
        $vpnClientPackage = Get-AzVpnClientPackage -ResourceGroupName $ResourceGroupName -VirtualNetworkGatewayName $GatewayName -ProcessorArchitecture "Amd64"
        Invoke-WebRequest -Uri $vpnClientPackage.VpnProfileSasUrl -OutFile $ProfilePath
        
        # Extract and modify VPN profiles
        $extractPath = "$PSScriptRoot\VpnProfile"
        if (Test-Path $extractPath) {
            Remove-Item -Path $extractPath -Recurse -Force
        }
        
        Write-Host "Extracting and modifying VPN profiles..." -ForegroundColor Yellow
        Expand-Archive -Path $ProfilePath -DestinationPath $extractPath
        
        # Modify the VPN profiles to enable/disable split tunneling
        $profiles = Get-ChildItem -Path $extractPath -Filter "*.pbk" -Recurse
        foreach ($profile in $profiles) {
            $content = Get-Content -Path $profile.FullName
            
            if ($Enable) {
                # Enable split tunneling by setting UseRasCredentials=1
                $content = $content -replace "UseRasCredentials=0", "UseRasCredentials=1"
                
                # Add routes if specified
                if ($Routes) {
                    $routeEntries = ""
                    foreach ($route in $Routes) {
                        $routeEntries += "IPADDR=$route`r`n"
                    }
                    
                    # Insert routes before the [NETCOMPONENTS] section
                    $content = $content -replace "\[NETCOMPONENTS\]", "$routeEntries`r`n[NETCOMPONENTS]"
                }
            }
            else {
                # Disable split tunneling
                $content = $content -replace "UseRasCredentials=1", "UseRasCredentials=0"
            }
            
            $content | Set-Content -Path $profile.FullName
        }
        
        # Repackage the VPN profiles
        $modifiedProfilePath = "$PSScriptRoot\ModifiedVpnProfile.zip"
        if (Test-Path $modifiedProfilePath) {
            Remove-Item -Path $modifiedProfilePath -Force
        }
        
        Write-Host "Creating modified VPN client package..." -ForegroundColor Yellow
        Compress-Archive -Path "$extractPath\*" -DestinationPath $modifiedProfilePath
        
        Write-Host "VPN split tunneling configuration completed successfully." -ForegroundColor Green
        Write-Host "Modified VPN client package available at: $modifiedProfilePath" -ForegroundColor Green
        Write-Host "Please distribute this package to your VPN clients." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to configure VPN split tunneling: $_"
    }
    finally {
        # Clean up temporary files
        if (Test-Path "$PSScriptRoot\VpnProfile") {
            Remove-Item -Path "$PSScriptRoot\VpnProfile" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}