<#
.SYNOPSIS
    Downloads and installs Synergy (commercial KVM software).
.DESCRIPTION
    Downloads the Synergy installer and attempts to run it.
    Since Synergy is commercial software, this will download the trial version.
.NOTES
    Author: Jurie Smit
    Date: March 12, 2025
#>
function Install-Synergy {
    [CmdletBinding()]
    param()
    
    Write-Host "Installing Synergy (Commercial)..." -ForegroundColor Cyan

    # URL for the Synergy installer
    $url = "https://symless.com/synergy/download/direct?platform=win"
    $installerPath = "$env:TEMP\SynergySetup.exe"
    
    Write-Host "Downloading Synergy installer from:" -ForegroundColor Yellow
    Write-Host "  $url"
    
    try {
        # Use TLS 1.2 for secure connections
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Add user agent to avoid being blocked
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "PowerShell Script")
        $webClient.DownloadFile($url, $installerPath)
        
        Write-Host "Download complete. Installer saved to:" -ForegroundColor Green
        Write-Host "  $installerPath"
    }
    catch {
        Write-Host "Error downloading Synergy installer: $_" -ForegroundColor Red
        Write-Host "Exception details:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        
        Write-Host "You can manually download Synergy from: https://symless.com/synergy/download" -ForegroundColor Yellow
        return
    }
    
    # Verify file was downloaded and has content
    if (-not (Test-Path $installerPath) -or (Get-Item $installerPath).Length -eq 0) {
        Write-Host "Error: The installer file is missing or empty." -ForegroundColor Red
        return
    }
    
    Write-Host "Launching Synergy installer..." -ForegroundColor Cyan
    Write-Host "NOTE: Synergy is commercial software. This will install the trial version." -ForegroundColor Yellow
    Write-Host "      You will need to purchase a license for continued use." -ForegroundColor Yellow
    
    try {
        # Launch the installer (Synergy installer typically requires user interaction)
        Start-Process -FilePath $installerPath -Wait
        
        # Check common installation paths
        $synergyPath = "${env:ProgramFiles}\Synergy\synergy.exe"
        $synergyPath32 = "${env:ProgramFiles(x86)}\Synergy\synergy.exe"
        
        if (Test-Path $synergyPath -or Test-Path $synergyPath32) {
            Write-Host "Synergy installation completed successfully." -ForegroundColor Green
        } else {
            Write-Host "Synergy installer ran, but the application wasn't found in the expected location." -ForegroundColor Yellow
            Write-Host "You may need to complete the installation manually." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error launching Synergy installer: $_" -ForegroundColor Red
        Write-Host "You may need to run the installer manually from: $installerPath" -ForegroundColor Yellow
    }
}