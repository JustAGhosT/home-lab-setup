<#
.SYNOPSIS
    Initiates the installation process for Mouse Without Borders.
.DESCRIPTION
    Opens the Mouse Without Borders download page in the default browser,
    allowing the user to manually download and install the software.
    Mouse Without Borders does not offer a straightforward silent install.
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Install-MouseWithoutBorders {
    [CmdletBinding()]
    param()
    
    Write-Host "Installing Mouse Without Borders..." -ForegroundColor Cyan
    
    # URL for Mouse Without Borders download page on Microsoft.com
    $downloadUrl = "https://www.microsoft.com/en-us/download/details.aspx?id=35460"
    Write-Host "Opening Mouse Without Borders download page in your default browser..." -ForegroundColor Yellow
    try {
        Start-Process -FilePath $downloadUrl
        Write-Host "Please download and run the installer manually." -ForegroundColor Green
    }
    catch {
        Write-Host "Error opening the download page: $_" -ForegroundColor Red
    }
}