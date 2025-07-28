function Disconnect-GitHub {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    try {
        # Check if Test-GitHubConnection function is available
        $testConnectionCmd = Get-Command -Name Test-GitHubConnection -ErrorAction SilentlyContinue
        if (-not $testConnectionCmd) {
            Write-Warning "Test-GitHubConnection function is not available. The HomeLab.GitHub module may not be fully loaded."
            Write-Host "Proceeding with disconnection anyway..." -ForegroundColor Yellow
            $isConnected = $true  # Assume connected to proceed with cleanup
        }
        else {
            # Check if currently connected
            try {
                $isConnected = Test-GitHubConnection -Quiet
            }
            catch {
                Write-Warning "Failed to test GitHub connection: $($_.Exception.Message)"
                Write-Host "Proceeding with disconnection anyway..." -ForegroundColor Yellow
                $isConnected = $true  # Assume connected to proceed with cleanup
            }
        }
        
        if (-not $isConnected) {
            Write-Host "Not currently connected to GitHub." -ForegroundColor Yellow
            return $true
        }
        
        # Get current user info for confirmation
        $config = Get-GitHubConfiguration
        $username = if ($config.Username) { $config.Username } else { "Unknown" }
        
        # Confirm disconnection unless Force is specified
        if (-not $Force) {
            Write-Host "Currently connected to GitHub as: $username" -ForegroundColor Gray
            $confirmation = Read-Host "Are you sure you want to disconnect? (y/N)"
            
            if ($confirmation -notmatch '^[Yy]') {
                Write-Host "Disconnection cancelled." -ForegroundColor Yellow
                return $false
            }
        }
        
        Write-Host "Disconnecting from GitHub..." -ForegroundColor Yellow
        
        # Remove stored token
        Remove-GitHubToken
        
        # Clear configuration
        $configPath = Get-GitHubConfigPath
        if (Test-Path $configPath) {
            Remove-Item -Path $configPath -Force
            Write-Verbose "Removed GitHub configuration file"
        }
        
        Write-Host "SUCCESS: Successfully disconnected from GitHub" -ForegroundColor Green
        Write-Host "  - Authentication token removed" -ForegroundColor Gray
        Write-Host "  - Configuration cleared" -ForegroundColor Gray
        Write-Host ""
        Write-Host "To reconnect, use: Connect-GitHub" -ForegroundColor Cyan
        
        return $true
    }
    catch {
        Write-Error "Failed to disconnect from GitHub: $($_.Exception.Message)"
        return $false
    }
}
