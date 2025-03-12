<#
.SYNOPSIS
    Configures Input Leap in client mode.
.DESCRIPTION
    Helper function to configure Input Leap as a client.
#>
function Configure-InputLeapClient {
    Write-Host "`nConfiguring Input Leap Client..." -ForegroundColor Cyan
    
    # Get server information
    Write-Host "Enter the name or IP address of the Input Leap server:" -ForegroundColor Yellow
    $serverAddress = Read-Host
    
    if (-not $serverAddress) {
        Write-Host "Server address is required. Configuration canceled." -ForegroundColor Red
        return
    }
    
    Write-Host "`nConfiguration complete. To use Input Leap as a client:" -ForegroundColor Green
    Write-Host "1. Start Input Leap" -ForegroundColor White
    Write-Host "2. Select 'Client' mode" -ForegroundColor White
    Write-Host "3. Enter the server address: $serverAddress" -ForegroundColor White
    Write-Host "4. Start the client" -ForegroundColor White
    Write-Host "`nMake sure to allow Input Leap through your firewall." -ForegroundColor Yellow
}