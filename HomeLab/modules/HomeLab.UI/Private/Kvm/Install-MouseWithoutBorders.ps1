<#
.SYNOPSIS
    Downloads and installs Microsoft Mouse Without Borders.
.DESCRIPTION
    Downloads Microsoft Mouse Without Borders from Microsoft's website and installs it.
.NOTES
    Author: Jurie Smit
    Date: March 12, 2025
#>
function Install-MouseWithoutBorders {
    [CmdletBinding()]
    param()
    
    Write-Host "Installing Microsoft Mouse Without Borders..." -ForegroundColor Cyan

    # URL for Mouse Without Borders from Microsoft
    $url = "https://download.microsoft.com/download/6/5/8/658AFC4C-DC02-4CB8-839D-10253E89FFF7/MouseWithoutBordersSetup.msi"
    $installerPath = "$env:TEMP\MouseWithoutBordersSetup.msi"
    
    Write-Host "Downloading Mouse Without Borders installer from:" -ForegroundColor Yellow
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
        Write-Host "Error downloading Mouse Without Borders installer: $_" -ForegroundColor Red
        Write-Host "Exception details:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        
        Write-Host "You can manually download Mouse Without Borders from the Microsoft Garage website." -ForegroundColor Yellow
        return
    }
    
    # Verify file was downloaded and has content
    if (-not (Test-Path $installerPath) -or (Get-Item $installerPath).Length -eq 0) {
        Write-Host "Error: The installer file is missing or empty." -ForegroundColor Red
        return
    }
    
    Write-Host "Installing Mouse Without Borders..." -ForegroundColor Cyan
    try {
        # Install the MSI silently
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /quiet" -Wait -NoNewWindow
        
        # Check if Mouse Without Borders was installed successfully
        $mwbPath = "${env:ProgramFiles}\Microsoft Garage\Mouse without Borders\MouseWithoutBorders.exe"
        $mwbPath32 = "${env:ProgramFiles(x86)}\Microsoft Garage\Mouse without Borders\MouseWithoutBorders.exe"
        
        if (Test-Path $mwbPath -or Test-Path $mwbPath32) {
            Write-Host "Mouse Without Borders installation completed successfully." -ForegroundColor Green
        } else {
            Write-Host "Mouse Without Borders installer ran, but the application wasn't found in the expected location." -ForegroundColor Yellow
            Write-Host "You may need to complete the installation manually." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error installing Mouse Without Borders: $_" -ForegroundColor Red
        Write-Host "You may need to run the installer manually from: $installerPath" -ForegroundColor Yellow
    }
}