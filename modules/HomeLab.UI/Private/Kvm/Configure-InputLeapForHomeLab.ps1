<#
.SYNOPSIS
    Configures Input Leap for a home lab environment.
.DESCRIPTION
    Guides the user through configuring Input Leap for a typical home lab setup,
    including server and client configuration.
.NOTES
    Author: Jurie Smit
    Date: March 12, 2025
#>
function Configure-InputLeapForHomeLab {
    [CmdletBinding()]
    param()
    
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                  INPUT LEAP HOME LAB CONFIGURATION               ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Check if Input Leap is installed
    $inputLeapPath = "${env:ProgramFiles}\InputLeap\input-leap.exe"
    $inputLeapPath32 = "${env:ProgramFiles(x86)}\InputLeap\input-leap.exe"
    
    if (-not (Test-Path $inputLeapPath) -and -not (Test-Path $inputLeapPath32)) {
        Write-Host "Input Leap doesn't appear to be installed." -ForegroundColor Red
        Write-Host "Would you like to install it now? (Y/N)" -ForegroundColor Yellow
        $install = Read-Host
        
        if ($install -eq "Y" -or $install -eq "y") {
            Install-InputLeap
            # Re-check installation
            if (-not (Test-Path $inputLeapPath) -and -not (Test-Path $inputLeapPath32)) {
                Write-Host "Input Leap installation failed or wasn't completed. Please install manually." -ForegroundColor Red
                return
            }
        } else {
            Write-Host "Configuration canceled. Please install Input Leap first." -ForegroundColor Yellow
            return
        }
    }
    
    # Determine which computer role to configure
    Write-Host "Is this computer the:" -ForegroundColor Yellow
    Write-Host "  1. Server (main computer with keyboard and mouse)" -ForegroundColor White
    Write-Host "  2. Client (secondary computer)" -ForegroundColor White
    $role = Read-Host "Select an option (1 or 2)"
    
    if ($role -eq "1") {
        # Server configuration
        Configure-InputLeapServer
    } elseif ($role -eq "2") {
        # Client configuration
        Configure-InputLeapClient
    } else {
        Write-Host "Invalid selection. Please choose 1 (Server) or 2 (Client)." -ForegroundColor Red
        return
    }
}