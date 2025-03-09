<#
.SYNOPSIS
    Displays the Software KVM Setup Menu.
.DESCRIPTION
    Shows the KVM menu options for installing and configuring software-based KVM solutions.
    Options include installing Barrier, Synergy, Mouse Without Borders, ShareMouse, or
    configuring Barrier for a home lab setup.
.PARAMETER ShowProgress
    If specified, shows a progress bar while loading the menu.
.EXAMPLE
    Show-KVMMenu
.EXAMPLE
    Show-KVMMenu -ShowProgress
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Show-KVMMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress
    )
    
    if ($ShowProgress) {
        $progressParams = @{
            Activity        = "Loading KVM Setup Menu"
            Status          = "Preparing options..."
            PercentComplete = 0
        }
        Write-Progress @progressParams
        Start-Sleep -Milliseconds 300

        $progressParams.Status = "Loading configuration..."
        $progressParams.PercentComplete = 30
        Write-Progress @progressParams
        Start-Sleep -Milliseconds 300

        $progressParams.Status = "Checking system requirements..."
        $progressParams.PercentComplete = 60
        Write-Progress @progressParams
        Start-Sleep -Milliseconds 300

        $progressParams.Status = "Ready"
        $progressParams.PercentComplete = 100
        Write-Progress @progressParams
        Start-Sleep -Milliseconds 300

        Write-Progress -Activity "Loading KVM Setup Menu" -Completed
    }
    
    Clear-Host
    
    # Display the menu header with ASCII art.
    Write-ColorOutput @"
    
╔══════════════════════════════════════════════════════════════════╗
║                      KVM SOFTWARE SETUP MENU                     ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
    
    # Display menu options.
    Write-ColorOutput "  1. Install Barrier (Open Source)" -ForegroundColor White
    Write-ColorOutput "  2. Install Synergy (Commercial)" -ForegroundColor White
    Write-ColorOutput "  3. Install Mouse Without Borders (Microsoft)" -ForegroundColor White
    Write-ColorOutput "  4. Install ShareMouse (Commercial)" -ForegroundColor White
    Write-ColorOutput "  5. Configure Barrier for Home Lab" -ForegroundColor White
    Write-ColorOutput "  0. Return to Main Menu" -ForegroundColor White
    Write-ColorOutput ""
    
    # Get user selection.
    $choice = Read-Host "Select an option"
    
    return @{
        Choice = $choice
        IsExit = ($choice -eq "0")
    }
}
