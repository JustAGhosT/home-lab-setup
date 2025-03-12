<#
.SYNOPSIS
    Handles the Software KVM Setup Menu interactions.
.DESCRIPTION
    Displays and processes user selections from the KVM Setup menu for
    installing and configuring software-based KVM solutions.
.PARAMETER ShowProgress
    If specified, shows a progress bar while loading the menu.
.PARAMETER State
    Optional hashtable to maintain state between menu calls.
.EXAMPLE
    Invoke-KvmSetupMenu
.EXAMPLE
    Invoke-KvmSetupMenu -ShowProgress
.NOTES
    Author: Jurie Smit
    Date: March 12, 2025
#>
function Invoke-KvmSetupMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$State = @{}
    )
    
    # Initialize exit flag
    $exitSubmenu = $false
    
    # KVM menu loop
    do {
        # Show progress if requested
        if ($ShowProgress) {
            Write-Progress -Activity "Loading KVM Setup Menu" -Status "Preparing options..." -PercentComplete 50
            Start-Sleep -Milliseconds 300
            Write-Progress -Activity "Loading KVM Setup Menu" -Status "Ready" -PercentComplete 100
            Start-Sleep -Milliseconds 300
            Write-Progress -Activity "Loading KVM Setup Menu" -Completed
        }
        
        # Display menu
        Clear-Host
        Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║                      KVM SOFTWARE SETUP MENU                     ║" -ForegroundColor Cyan
        Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  1. Install Input Leap (Open Source, Recommended)" -ForegroundColor White
        Write-Host "  2. Install Synergy (Commercial)" -ForegroundColor White
        Write-Host "  3. Install Mouse Without Borders (Microsoft)" -ForegroundColor White
        Write-Host "  4. Install ShareMouse (Commercial)" -ForegroundColor White
        Write-Host "  5. Configure Input Leap for Home Lab" -ForegroundColor White
        Write-Host "  0. Return to Main Menu" -ForegroundColor White
        Write-Host ""
        
        # Get user choice
        $choice = Read-Host "Select an option"
        
        # Process choice
        try {
            switch ($choice) {
                "0" { 
                    $exitSubmenu = $true 
                }
                "1" {
                    Install-InputLeap
                    Write-Host "`nPress Enter to return to the menu..." -ForegroundColor Yellow
                    Read-Host | Out-Null
                }
                "2" {
                    Install-Synergy
                    Write-Host "`nPress Enter to return to the menu..." -ForegroundColor Yellow
                    Read-Host | Out-Null
                }
                "3" {
                    Install-MouseWithoutBorders
                    Write-Host "`nPress Enter to return to the menu..." -ForegroundColor Yellow
                    Read-Host | Out-Null
                }
                "4" {
                    Install-ShareMouse
                    Write-Host "`nPress Enter to return to the menu..." -ForegroundColor Yellow
                    Read-Host | Out-Null
                }
                "5" {
                    Configure-InputLeapForHomeLab
                    Write-Host "`nPress Enter to return to the menu..." -ForegroundColor Yellow
                    Read-Host | Out-Null
                }
                default {
                    Write-Host "`nInvalid selection: $choice" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                }
            }
        }
        catch {
            $errorMessage = "Error processing menu choice: $($_.Exception.Message)"
            Write-Host "`n$errorMessage`n" -ForegroundColor Red
            
            # Log error if Write-Log function exists
            if (Get-Command -Name Write-Log -ErrorAction SilentlyContinue) {
                Write-Log -Message $errorMessage -Level "Error" -Force
            }
            
            Write-Host "`nPress Enter to return to the menu..." -ForegroundColor Yellow
            Read-Host | Out-Null
        }
        
        # Only show progress on first display
        $ShowProgress = $false
        
    } while (-not $exitSubmenu)
    
    return $true
}