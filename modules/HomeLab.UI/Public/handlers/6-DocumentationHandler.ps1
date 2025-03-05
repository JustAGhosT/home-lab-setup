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
    Date: March 5, 2025
#>
function Invoke-DocumentationMenu {
    [CmdletBinding()]
    param()
    
    # Determine the project root. Assuming this file is in the "menu" folder, the project root is its parent.
    $projectRoot = Split-Path -Parent $PSScriptRoot
    $docsPath = Join-Path -Path $projectRoot -ChildPath "docs"
    
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
                
                $readmePath = Join-Path -Path $projectRoot -ChildPath "README.md"
                if (Test-Path $readmePath) {
                    Get-Content $readmePath | ForEach-Object { Write-Host $_ }
                }
                else {
                    Write-Host "README.md not found." -ForegroundColor Red
                }
                Pause
            }
            "2" {
                Clear-Host
                Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
                Write-Host "║         VPN GATEWAY DOCUMENTATION        ║" -ForegroundColor Cyan
                Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
                Write-Host ""
                
                $vpnReadmePath = Join-Path -Path $docsPath -ChildPath "VPN-GATEWAY.README.md"
                if (Test-Path $vpnReadmePath) {
                    Get-Content $vpnReadmePath | ForEach-Object { Write-Host $_ }
                }
                else {
                    Write-Host "VPN Gateway documentation not found." -ForegroundColor Red
                }
                Pause
            }
            "3" {
                Clear-Host
                Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
                Write-Host "║   CLIENT CERTIFICATE MANAGEMENT GUIDE    ║" -ForegroundColor Cyan
                Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
                Write-Host ""
                
                $certGuidePath = Join-Path -Path $docsPath -ChildPath "client-certificate-management.md"
                if (Test-Path $certGuidePath) {
                    Get-Content $certGuidePath | ForEach-Object { Write-Host $_ }
                }
                else {
                    Write-Host "Client certificate management guide not found." -ForegroundColor Red
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

Export-ModuleMember -Function Invoke-DocumentationMenu
