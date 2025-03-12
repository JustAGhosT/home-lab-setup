<#
.SYNOPSIS
    Downloads and installs ShareMouse (commercial KVM software).
.DESCRIPTION
    Downloads the ShareMouse installer and attempts to run it.
    Since ShareMouse is commercial software, this will download the trial version.
.NOTES
    Author: Jurie Smit
    Date: March 12, 2025
#>
function Install-ShareMouse {
    [CmdletBinding()]
    param()
    
    Write-Host "Installing ShareMouse (Commercial)..." -ForegroundColor Cyan

    # URL for the ShareMouse installer
    $url = "https://www.sharemouse.com/ShareMouseSetup.exe"
    $installerPath = "$env:TEMP\ShareMouseSetup.exe"
    
    Write-Host "Downloading ShareMouse installer from:" -ForegroundColor Yellow
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
        Write-Host "Error downloading ShareMouse installer: $_" -ForegroundColor Red
        Write-Host "Exception details:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        
        Write-Host "You can manually download ShareMouse from: https://www.sharemouse.com/download/" -ForegroundColor Yellow
        return
    }
    
    # Verify file was downloaded and has content
    if (-not (Test-Path $installerPath) -or (Get-Item $installerPath).Length -eq 0) {
        Write-Host "Error: The installer file is missing or empty." -ForegroundColor Red
        return
    }
    
    Write-Host "Launching ShareMouse installer..." -ForegroundColor Cyan
    Write-Host "NOTE: ShareMouse is commercial software. This will install the trial version." -ForegroundColor Yellow
    Write-Host "      You will need to purchase a license for continued use." -ForegroundColor Yellow
    
    try {
        # Launch the installer (ShareMouse installer typically requires user interaction)
        Start-Process -FilePath $installerPath -Wait
        
        # Check common installation paths
        $shareMousePath = "${env:ProgramFiles}\ShareMouse\ShareMouse.exe"
        $shareMousePath32 = "${env:ProgramFiles(x86)}\ShareMouse\ShareMouse.exe"
        
        if (Test-Path $shareMousePath -or Test-Path $shareMousePath32) {
            Write-Host "ShareMouse installation completed successfully." -ForegroundColor Green
        } else {
            Write-Host "ShareMouse installer ran, but the application wasn't found in the expected location." -ForegroundColor Yellow
            Write-Host "You may need to complete the installation manually." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error launching ShareMouse installer: $_" -ForegroundColor Red
        Write-Host "You may need to run the installer manually from: $installerPath" -ForegroundColor Yellow
    }
}
