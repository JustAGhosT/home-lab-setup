<#
.SYNOPSIS
    Configures Barrier for Home Lab Setup.
.DESCRIPTION
    Displays recommended instructions for setting up Barrier in a multi-computer environment.
    This includes guidance for configuring a primary server and one or more client machines.
    Optionally, you could extend this function to automate writing a configuration file.
.EXAMPLE
    Configure-Barrier
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Configure-Barrier {
    [CmdletBinding()]
    param()
    
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "      Barrier Configuration Setup       " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Recommended Setup for Home Lab:" -ForegroundColor White
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host "  Server: Primary PC (e.g., P1) with keyboard/mouse" -ForegroundColor White
    Write-Host "  Clients: Additional PCs (e.g., L1, L2)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Screen Layout Example:" -ForegroundColor White
    Write-Host "   +-------+-------+" -ForegroundColor White
    Write-Host "   |  L1   |  P1   |" -ForegroundColor White
    Write-Host "   +-------+-------+" -ForegroundColor White
    Write-Host "           |       |" -ForegroundColor White
    Write-Host "           |  L2   |" -ForegroundColor White
    Write-Host "           |       |" -ForegroundColor White
    Write-Host "           +-------+" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Steps to Configure Barrier:" -ForegroundColor White
    Write-Host "  1. On the primary computer (server), launch Barrier and select 'Server' mode." -ForegroundColor White
    Write-Host "  2. Click 'Configure Server' and add client screens, naming them appropriately (e.g., L1, L2)." -ForegroundColor White
    Write-Host "  3. Arrange the screens to reflect your physical monitor layout." -ForegroundColor White
    Write-Host "  4. Save the configuration." -ForegroundColor White
    Write-Host "  5. On each client computer, launch Barrier, select 'Client' mode," -ForegroundColor White
    Write-Host "     and enter the server's IP address." -ForegroundColor White
    Write-Host "  6. (Optional) Enable SSL encryption and set a shared password for secure communication." -ForegroundColor White
    Write-Host ""
    
    Write-Host "For further automation, consider creating a Barrier configuration file" -ForegroundColor White
    Write-Host "and deploying it to client machines. Refer to Barrier's documentation for details." -ForegroundColor White
    Write-Host ""
    
    Pause-ForUser
}