function Connect-GitHub {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Token
    )
    
    try {
        Write-Host "Connecting to GitHub..." -ForegroundColor Yellow
        
        # Get token if not provided
        if (-not $Token) {
            Write-Host "GitHub Personal Access Token required." -ForegroundColor Cyan
            Write-Host "To create a token, go to: https://github.com/settings/tokens" -ForegroundColor Gray

            $secureToken = Read-Host "Enter your GitHub Personal Access Token" -AsSecureString

            # Convert SecureString to plain text only at the point of use
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
            try {
                $Token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                # Store the token immediately
                Set-GitHubToken -Token $Token
                # Clear the plain text token from memory
                $Token = $null
            }
            finally {
                # Always clear the BSTR from memory
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
            }
        }
        else {
            # Store the provided token
            Set-GitHubToken -Token $Token
        }
        
        Write-Host "Testing GitHub connection..." -ForegroundColor Yellow
        
        # Test the connection
        $user = Invoke-GitHubApi -Endpoint "/user" -Method GET
        
        if ($user -and $user.login) {
            Write-Host "SUCCESS: Connected to GitHub!" -ForegroundColor Green
            Write-Host "  User: $($user.login)" -ForegroundColor Gray
            Write-Host "  Name: $($user.name)" -ForegroundColor Gray
            
            # Store user info in configuration
            $config = @{
                Username    = $user.login
                Name        = $user.name
                Email       = $user.email
                ConnectedAt = Get-Date
            }
            
            Set-GitHubConfiguration -Configuration $config
            
            Write-Host ""
            Write-Host "GitHub integration is ready!" -ForegroundColor Cyan
            Write-Host "  - Get-GitHubRepositories" -ForegroundColor Gray
            Write-Host "  - Select-GitHubRepository" -ForegroundColor Gray
            Write-Host "  - Deploy-GitHubRepository" -ForegroundColor Gray
            
            return $true
        }
        else {
            throw "Failed to retrieve user information from GitHub API"
        }
    }
    catch {
        Write-Error "GitHub authentication failed: $($_.Exception.Message)"
        return $false
    }
}
