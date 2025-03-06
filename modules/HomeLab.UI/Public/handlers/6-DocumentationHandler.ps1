<#
.SYNOPSIS
    Documentation Menu Handler for HomeLab Setup
.DESCRIPTION
    Processes user selections in the documentation menu using the new modular structure.
    Options include:
      1. Viewing the Main README.
      2. Viewing VPN Gateway Documentation.
      3. Viewing the Client Certificate Management Guide.
      0. Return to the Main Menu.
.EXAMPLE
    Invoke-DocumentationMenu
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Invoke-DocumentationMenu {
    [CmdletBinding()]
    param()
    
    # Determine the module root and docs path
    $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $docsPath = Join-Path -Path $moduleRoot -ChildPath "docs"
    
    $selection = 0
    do {
        Show-DocumentationMenu
        $selection = Read-Host "Select an option"
        
        switch ($selection) {
            "1" {
                Clear-Host
                Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
                Write-Host "║             MAIN README                  ║" -ForegroundColor Cyan
                Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
                Write-Host ""
                
                $readmePath = Join-Path -Path $moduleRoot -ChildPath "..\README.md"
                if (Test-Path $readmePath) {
                    Get-Content $readmePath | ForEach-Object { Write-Host $_ }
                }
                else {
                    Write-Host "README.md not found at $readmePath." -ForegroundColor Red
                    
                    # Try alternate location
                    $altReadmePath = Join-Path -Path $moduleRoot -ChildPath "README.md"
                    if (Test-Path $altReadmePath) {
                        Get-Content $altReadmePath | ForEach-Object { Write-Host $_ }
                    }
                    else {
                        Write-Host "README.md not found at alternate location $altReadmePath." -ForegroundColor Red
                    }
                }
                
                Pause
            }
            "2" {
                Clear-Host
                Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
                Write-Host "║         VPN GATEWAY DOCUMENTATION        ║" -ForegroundColor Cyan
                Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
                Write-Host ""
                
                # Try to find the VPN Gateway documentation
                $vpnReadmePath = Join-Path -Path $docsPath -ChildPath "VPN-GATEWAY.README.md"
                if (Test-Path $vpnReadmePath) {
                    Get-Content $vpnReadmePath | ForEach-Object { Write-Host $_ }
                }
                else {
                    # Try alternate locations
                    $altVpnReadmePath = Join-Path -Path $docsPath -ChildPath "vpn-gateway.md"
                    if (Test-Path $altVpnReadmePath) {
                        Get-Content $altVpnReadmePath | ForEach-Object { Write-Host $_ }
                    }
                    else {
                        Write-Host "VPN Gateway documentation not found." -ForegroundColor Red
                        Write-Host "Searched locations:" -ForegroundColor Yellow
                        Write-Host "- $vpnReadmePath" -ForegroundColor Yellow
                        Write-Host "- $altVpnReadmePath" -ForegroundColor Yellow
                    }
                }
                
                Pause
            }
            "3" {
                Clear-Host
                Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
                Write-Host "║   CLIENT CERTIFICATE MANAGEMENT GUIDE    ║" -ForegroundColor Cyan
                Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
                Write-Host ""
                
                # Try to find the Client Certificate Management guide
                $certGuidePath = Join-Path -Path $docsPath -ChildPath "client-certificate-management.md"
                if (Test-Path $certGuidePath) {
                    Get-Content $certGuidePath | ForEach-Object { Write-Host $_ }
                }
                else {
                    # Try alternate locations
                    $altCertGuidePath = Join-Path -Path $docsPath -ChildPath "vpn-certificates.md"
                    if (Test-Path $altCertGuidePath) {
                        Get-Content $altCertGuidePath | ForEach-Object { Write-Host $_ }
                    }
                    else {
                        Write-Host "Client certificate management guide not found." -ForegroundColor Red
                        Write-Host "Searched locations:" -ForegroundColor Yellow
                        Write-Host "- $certGuidePath" -ForegroundColor Yellow
                        Write-Host "- $altCertGuidePath" -ForegroundColor Yellow
                    }
                }
                
                Pause
            }
            "0" {
                # Return to main menu
            }
            default {
                Write-Host "Invalid option. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($selection -ne "0")
}
