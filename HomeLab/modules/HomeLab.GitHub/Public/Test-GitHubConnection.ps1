<#
.SYNOPSIS
    Tests the GitHub connection and authentication.

.DESCRIPTION
    Verifies that the stored GitHub token is valid and can be used to make API calls.

.PARAMETER Quiet
    Suppresses output and returns only a boolean result.

.EXAMPLE
    Test-GitHubConnection
    # Shows detailed connection status

.EXAMPLE
    if (Test-GitHubConnection -Quiet) { "Connected" } else { "Not connected" }
    # Returns boolean result only

.OUTPUTS
    Boolean. True if connected and authenticated, False otherwise.
#>
function Test-GitHubConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Quiet
    )
    
    try {
        # Check if token exists
        $token = Get-GitHubToken
        if (-not $token) {
            if (-not $Quiet) {
                Write-Host "ERROR: Not connected to GitHub. Run Connect-GitHub to authenticate." -ForegroundColor Red
            }
            return $false
        }
        
        if (-not $Quiet) {
            Write-Host "Testing GitHub connection..." -ForegroundColor Yellow
        }
        
        # Test API call
        $user = Invoke-GitHubApi -Endpoint "/user" -Method GET
        
        if ($user -and $user.login) {
            if (-not $Quiet) {
                Write-Host "SUCCESS: GitHub connection is active!" -ForegroundColor Green
                Write-Host "  Connected as: $($user.login)" -ForegroundColor Gray
                
                # Check rate limit
                $rateLimit = Invoke-GitHubApi -Endpoint "/rate_limit" -Method GET
                if ($rateLimit) {
                    $remaining = $rateLimit.rate.remaining
                    $limit = $rateLimit.rate.limit
                    $resetTime = [DateTimeOffset]::FromUnixTimeSeconds($rateLimit.rate.reset).ToString("yyyy-MM-dd HH:mm:ss")
                    
                    Write-Host "  Rate limit: $remaining/$limit remaining (resets at $resetTime)" -ForegroundColor Gray
                    
                    if ($remaining -lt 100) {
                        Write-Warning "GitHub API rate limit is low ($remaining remaining). Consider waiting before making many requests."
                    }
                }
            }
            return $true
        }
        else {
            if (-not $Quiet) {
                Write-Host "ERROR: GitHub connection test failed - invalid response" -ForegroundColor Red
            }
            return $false
        }
    }
    catch {
        if (-not $Quiet) {
            Write-Host "ERROR: GitHub connection test failed: $($_.Exception.Message)" -ForegroundColor Red
            
            # Provide helpful error messages based on common issues
            if ($_.Exception.Message -like "*401*" -or $_.Exception.Message -like "*Unauthorized*") {
                Write-Host "  This usually means your token is invalid or expired." -ForegroundColor Gray
                Write-Host "  Run Connect-GitHub -Force to re-authenticate." -ForegroundColor Gray
            }
            elseif ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*Forbidden*") {
                Write-Host "  This usually means your token lacks required permissions." -ForegroundColor Gray
                Write-Host "  Ensure your token has 'repo' and 'user' scopes." -ForegroundColor Gray
            }
            elseif ($_.Exception.Message -like "*network*" -or $_.Exception.Message -like "*timeout*") {
                Write-Host "  This appears to be a network connectivity issue." -ForegroundColor Gray
                Write-Host "  Check your internet connection and try again." -ForegroundColor Gray
            }
        }
        return $false
    }
}
