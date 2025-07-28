function Connect-GitHub {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Token,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    try {
        Write-Host "Connecting to GitHub..." -ForegroundColor Yellow
        
        # Get token if not provided
        $secureToken = $null
        if (-not $Token) {
            Write-Host "GitHub Personal Access Token required." -ForegroundColor Cyan
            Write-Host "To create a token, go to: https://github.com/settings/tokens" -ForegroundColor Gray

            $secureToken = Read-Host "Enter your GitHub Personal Access Token" -AsSecureString
        }

        Write-Host "Testing GitHub connection..." -ForegroundColor Yellow

        # Test the connection with error handling
        try {
            # Convert SecureString to plain text only at the point of use
            if ($secureToken) {
                $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
                try {
                    $plainToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                    Set-GitHubToken -Token $plainToken
                    # Clear the plain text token immediately
                    $plainToken = $null
                }
                finally {
                    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
                }
            }
            else {
                Set-GitHubToken -Token $Token
            }

            $user = Invoke-GitHubApi -Endpoint "/user" -Method GET
        }
        catch [System.Net.WebException] {
            if ($_.Exception.Response.StatusCode -eq 401) {
                throw "Authentication failed: Invalid GitHub token. Please check your token and try again."
            }
            elseif ($_.Exception.Response.StatusCode -eq 403) {
                throw "API rate limit exceeded or insufficient permissions. Please wait and try again."
            }
            else {
                throw "Network error occurred while connecting to GitHub: $($_.Exception.Message)"
            }
        }
        catch {
            throw "Failed to connect to GitHub API: $($_.Exception.Message)"
        }
        
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
