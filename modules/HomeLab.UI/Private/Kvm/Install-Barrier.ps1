<#
.SYNOPSIS
    Downloads and installs Barrier (open source KVM software).
.DESCRIPTION
    Downloads the Barrier installer from GitHub and attempts to run it silently.
    Adjust the URL and silent parameters as needed for your environment.
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Install-Barrier {
    [CmdletBinding()]
    param()
    
    Write-Host "Installing Barrier..." -ForegroundColor Cyan

    # URL for the Barrier installer from GitHub releases (update version as needed)
    $url = "https://github.com/debauchee/barrier/releases/download/v2.3.3/BarrierSetup.exe"
    $installerPath = "$env:TEMP\BarrierSetup.exe"
    
    Write-Host "Downloading Barrier installer from:" -ForegroundColor Yellow
    Write-Host "  $url"
    try {
        Invoke-WebRequest -Uri $url -OutFile $installerPath -UseBasicParsing
        Write-Host "Download complete. Installer saved to:" -ForegroundColor Green
        Write-Host "  $installerPath"
    }
    catch {
        Write-Host "Error downloading Barrier installer: $_" -ForegroundColor Red
        return
    }
    
    Write-Host "Launching Barrier installer..." -ForegroundColor Cyan
    try {
        # Attempt a silent installation (/S is common for NSIS installers).
        # Modify the arguments if a different silent flag is required.
        Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
        Write-Host "Barrier installation completed." -ForegroundColor Green
    }
    catch {
        Write-Host "Error launching Barrier installer: $_" -ForegroundColor Red
    }
}