<#
.SYNOPSIS
    Downloads and installs Input Leap (open source KVM software).
.DESCRIPTION
    Downloads the Input Leap installer from GitHub and attempts to run it silently.
    Input Leap is the actively maintained successor to Barrier.
.NOTES
    Author: Jurie Smit
    Date: March 12, 2025
#>
function Install-InputLeap {
    [CmdletBinding()]
    param()
    
    Write-Host "Installing Input Leap..." -ForegroundColor Cyan

    # URL for the Input Leap installer from GitHub releases
    $url = "https://github.com/input-leap/input-leap/releases/download/v3.0.2/InputLeap_3.0.2_windows_qt6.exe"
    $installerPath = "$env:TEMP\InputLeapSetup.exe"
    
    Write-Host "Downloading Input Leap installer from:" -ForegroundColor Yellow
    Write-Host "  $url"
    
    try {
        # Use TLS 1.2 for GitHub connections
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Add user agent to avoid being blocked
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "PowerShell Script")
        $webClient.DownloadFile($url, $installerPath)
        
        Write-Host "Download complete. Installer saved to:" -ForegroundColor Green
        Write-Host "  $installerPath"
    }
    catch {
        Write-Host "Error downloading Input Leap installer: $_" -ForegroundColor Red
        
        # Provide more detailed error information
        Write-Host "Exception details:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        
        # Check if file exists at the destination
        if (Test-Path $installerPath) {
            Write-Host "Note: A file already exists at $installerPath. It might be incomplete or corrupted." -ForegroundColor Yellow
        }
        
        return
    }
    
    # Verify file was downloaded and has content
    if (-not (Test-Path $installerPath) -or (Get-Item $installerPath).Length -eq 0) {
        Write-Host "Error: The installer file is missing or empty." -ForegroundColor Red
        return
    }
    
    Write-Host "Launching Input Leap installer..." -ForegroundColor Cyan
    try {
        # Attempt a silent installation (/S is common for NSIS installers)
        Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait -NoNewWindow
        
        # Check if Input Leap was installed successfully
        $inputLeapPath = "${env:ProgramFiles}\Input Leap\input-leap.exe"
        $inputLeapPath32 = "${env:ProgramFiles(x86)}\Input Leap\input-leap.exe"
        
        if (Test-Path $inputLeapPath -or Test-Path $inputLeapPath32) {
            Write-Host "Input Leap installation completed successfully." -ForegroundColor Green
        } else {
            Write-Host "Input Leap installer ran, but the application wasn't found in the expected location." -ForegroundColor Yellow
            Write-Host "You may need to complete the installation manually." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error launching Input Leap installer: $_" -ForegroundColor Red
        Write-Host "You may need to run the installer manually from: $installerPath" -ForegroundColor Yellow
    }
}
