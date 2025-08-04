function Get-GitHubTokenFromUser {
    <#
    .SYNOPSIS
        Manages GitHub token acquisition, validation, and storage.
    
    .DESCRIPTION
        This function provides a comprehensive GitHub token management system that:
        - Checks for existing tokens in environment variables
        - Guides users to create new tokens
        - Validates tokens against GitHub API
        - Stores tokens securely in user environment variables
    
    .OUTPUTS
        Returns the GitHub token as a plain string if successful, null otherwise.
    
    .EXAMPLE
        $token = Get-GitHubTokenFromUser
        if ($token) {
            # Use token for GitHub API calls
        }
    #>
    [CmdletBinding()]
    param()
    
    Write-Log -Message "Checking for GitHub token" -Level "Info"
    
    # Check environment variables first
    $token = $env:GITHUB_TOKEN
    
    if ($token) {
        Write-Log -Message "Found existing GitHub token" -Level "Success"
        # Validate existing token
        if (Test-GitHubToken -Token $token) {
            return $token
        }
        else {
            Write-Log -Message "Existing token is invalid" -Level "Warning"
            $token = $null
        }
    }
    
    # No valid token found, prompt user
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│                    GitHub Token Required                        │" -ForegroundColor Cyan
    Write-Host "├─────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
    Write-Host "│ A Personal Access Token is needed to access your repositories  │" -ForegroundColor White
    Write-Host "│                                                                 │" -ForegroundColor White
    Write-Host "│ To create a token:                                             │" -ForegroundColor White
    Write-Host "│ 1. Go to: https://github.com/settings/tokens                  │" -ForegroundColor Yellow
    Write-Host "│ 2. Click 'Generate new token (classic)'                       │" -ForegroundColor Yellow
    Write-Host "│ 3. Give it a name like 'HomeLab Deployment'                   │" -ForegroundColor Yellow
    Write-Host "│ 4. Select scopes: 'repo' and 'workflow'                       │" -ForegroundColor Yellow
    Write-Host "│ 5. Click 'Generate token'                                     │" -ForegroundColor Yellow
    Write-Host "│ 6. Copy the token (you won't see it again!)                   │" -ForegroundColor Yellow
    Write-Host "└─────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
    
    $getTokenChoice = Read-Host "Enter GitHub token now? (y/n)"
    if ($getTokenChoice -eq "y") {
        do {
            $newToken = Read-Host "Paste your GitHub Personal Access Token" -AsSecureString
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($newToken)
            try {
                $plainToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                
                if (Test-GitHubToken -Token $plainToken) {
                    # Save to environment variables
                    $env:GITHUB_TOKEN = $plainToken
                    [Environment]::SetEnvironmentVariable("GITHUB_TOKEN", $plainToken, "User")
                    
                    Write-Log -Message "GitHub token validated and saved successfully" -Level "Success"
                    Write-Host "✅ Token validated and saved to environment variables!" -ForegroundColor Green
                    
                    return $plainToken
                }
                else {
                    Write-Host "❌ Invalid token. Please check and try again." -ForegroundColor Red
                    $retry = Read-Host "Try again? (y/n)"
                    if ($retry -ne "y") {
                        break
                    }
                }
            }
            finally {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
            }
        } while ($true)
    }
    
    return $null
}

function Test-GitHubToken {
    <#
    .SYNOPSIS
        Validates a GitHub token by testing it against the GitHub API.
    
    .PARAMETER Token
        The GitHub token to validate.
    
    .OUTPUTS
        Returns $true if the token is valid, $false otherwise.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Token
    )
    
    try {
        $headers = @{
            'Authorization' = "token $Token"
            'Accept' = 'application/vnd.github.v3+json'
            'User-Agent' = 'HomeLab-PowerShell'
        }
        
        $response = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -Method Get -ErrorAction Stop
        Write-Log -Message "GitHub token validated for user: $($response.login)" -Level "Success"
        Write-Host "👋 Hello, $($response.login)!" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Log -Message "GitHub token validation failed: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

function Get-GitHubRepositories {
    <#
    .SYNOPSIS
        Fetches GitHub repositories for the authenticated user.
    
    .PARAMETER Token
        The GitHub token to use for authentication.
    
    .PARAMETER IncludeOrganization
        Whether to include organization repositories.
    
    .PARAMETER MaxResults
        Maximum number of repositories to return (default: 50).
    
    .OUTPUTS
        Returns an array of repository objects sorted by last update.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Token,
        
        [Parameter()]
        [switch]$IncludeOrganization,
        
        [Parameter()]
        [int]$MaxResults = 50
    )
    
    try {
        $headers = @{
            'Authorization' = "token $Token"
            'Accept' = 'application/vnd.github.v3+json'
            'User-Agent' = 'HomeLab-PowerShell'
        }
        
        Write-Log -Message "Fetching GitHub repositories" -Level "Info"
        Write-Host "🔍 Fetching your repositories..." -ForegroundColor Yellow
        
        $allRepos = @()
        
        # Get owned repositories
        $ownedRepos = Invoke-RestMethod -Uri "https://api.github.com/user/repos?sort=updated&per_page=$MaxResults&type=owner" -Headers $headers -Method Get
        if ($ownedRepos) {
            $allRepos += $ownedRepos
            Write-Log -Message "Found $(@($ownedRepos).Count) owned repositories" -Level "Info"
        }
        
        # Get organization repositories if requested
        if ($IncludeOrganization) {
            $memberRepos = Invoke-RestMethod -Uri "https://api.github.com/user/repos?sort=updated&per_page=$MaxResults&type=member" -Headers $headers -Method Get
            if ($memberRepos) {
                $allRepos += $memberRepos
                Write-Log -Message "Found $(@($memberRepos).Count) organization repositories" -Level "Info"
            }
        }
        
        # Sort by last updated and return
        $sortedRepos = $allRepos | Sort-Object updated_at -Descending
        Write-Log -Message "Retrieved $(@($sortedRepos).Count) total repositories" -Level "Success"
        
        return $sortedRepos
    }
    catch {
        Write-Log -Message "Failed to fetch GitHub repositories: $($_.Exception.Message)" -Level "Error"
        Write-Host "❌ Failed to fetch repositories: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function Select-GitHubRepository {
    <#
    .SYNOPSIS
        Provides an interactive interface for selecting a GitHub repository.
    
    .PARAMETER Repositories
        Array of repository objects to choose from.
    
    .PARAMETER MaxDisplay
        Maximum number of repositories to display at once (default: 15).
    
    .OUTPUTS
        Returns the selected repository object or $null if cancelled.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Repositories,
        
        [Parameter()]
        [int]$MaxDisplay = 15
    )
    
    if (-not $Repositories -or $Repositories.Count -eq 0) {
        Write-Host "❌ No repositories available for selection." -ForegroundColor Red
        return $null
    }
    
    $displayCount = [Math]::Min($Repositories.Count, $MaxDisplay)
    
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│                     Select Repository                           │" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📚 Found $($Repositories.Count) repositories (showing top $displayCount):" -ForegroundColor Green
    Write-Host ""
    
    # Display repositories with rich formatting
    for ($i = 0; $i -lt $displayCount; $i++) {
        $repo = $Repositories[$i]
        $repoName = $repo.full_name
        $description = if ($repo.description) { $repo.description } else { "No description available" }
        $language = if ($repo.language) { $repo.language } else { "Unknown" }
        $lastUpdated = ([DateTime]$repo.updated_at).ToString("MMM dd, yyyy")
        $isPrivate = if ($repo.private) { "🔒" } else { "🔓" }
        
        # Truncate description if too long
        if ($description.Length -gt 60) {
            $description = $description.Substring(0, 57) + "..."
        }
        
        Write-Host "  $($i+1)." -ForegroundColor White -NoNewline
        Write-Host " $isPrivate $repoName" -ForegroundColor Cyan -NoNewline
        Write-Host " [$language]" -ForegroundColor Yellow
        Write-Host "     📝 $description" -ForegroundColor Gray
        Write-Host "     📅 Updated: $lastUpdated" -ForegroundColor DarkGray
        Write-Host ""
    }
    
    if ($Repositories.Count -gt $MaxDisplay) {
        Write-Host "     ... and $($Repositories.Count - $MaxDisplay) more repositories" -ForegroundColor DarkGray
        Write-Host ""
    }
    
    Write-Host "  M. 🔗 Enter repository URL manually" -ForegroundColor Green
    Write-Host "  Q. ❌ Cancel operation" -ForegroundColor Red
    Write-Host ""
    
    do {
        $choice = Read-Host "Select repository (1-$displayCount, M for manual, Q to quit)"
        
        if ($choice -eq "Q" -or $choice -eq "q") {
            Write-Log -Message "Repository selection cancelled by user" -Level "Info"
            return $null
        }
        
        if ($choice -eq "M" -or $choice -eq "m") {
            Write-Log -Message "Manual repository entry selected" -Level "Info"
            return @{ Manual = $true }
        }
        
        try {
            $index = [int]$choice - 1
            if ($index -ge 0 -and $index -lt $displayCount) {
                $selected = $Repositories[$index]
                Write-Log -Message "Selected repository: $($selected.full_name)" -Level "Success"
                Write-Host "✅ Selected: $($selected.full_name)" -ForegroundColor Green
                return $selected
            }
            else {
                Write-Host "❌ Invalid selection. Please choose 1-$displayCount, M, or Q." -ForegroundColor Red
            }
        }
        catch {
            Write-Host "❌ Invalid input. Please choose 1-$displayCount, M, or Q." -ForegroundColor Red
        }
    } while ($true)
}

function Select-GitHubBranch {
    <#
    .SYNOPSIS
        Provides an interactive interface for selecting a repository branch.
    
    .PARAMETER Repository
        The repository object to get branches from.
    
    .PARAMETER Token
        GitHub token for authentication.
    
    .OUTPUTS
        Returns the selected branch name or the default branch if no selection made.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Repository,
        
        [Parameter(Mandatory = $true)]
        [string]$Token
    )
    
    try {
        $headers = @{
            'Authorization' = "token $Token"
            'Accept' = 'application/vnd.github.v3+json'
            'User-Agent' = 'HomeLab-PowerShell'
        }
        
        Write-Host "🌿 Fetching branches for $($Repository.full_name)..." -ForegroundColor Yellow
        $branches = Invoke-RestMethod -Uri "$($Repository.url)/branches" -Headers $headers -Method Get
        
        if (-not $branches -or $branches.Count -eq 0) {
            Write-Log -Message "No branches found, using default: $($Repository.default_branch)" -Level "Warning"
            return $Repository.default_branch
        }
        
        Write-Host ""
        Write-Host "Available branches:" -ForegroundColor Cyan
        Write-Host ""
        
        for ($i = 0; $i -lt $branches.Count; $i++) {
            $branch = $branches[$i]
            $isDefault = if ($branch.name -eq $Repository.default_branch) { " ⭐ (default)" } else { "" }
            Write-Host "  $($i+1). $($branch.name)$isDefault" -ForegroundColor White
        }
        
        Write-Host ""
        $branchChoice = Read-Host "Select branch number or press Enter for default ($($Repository.default_branch))"
        
        if ([string]::IsNullOrWhiteSpace($branchChoice)) {
            Write-Log -Message "Using default branch: $($Repository.default_branch)" -Level "Info"
            return $Repository.default_branch
        }
        
        try {
            $branchIndex = [int]$branchChoice - 1
            if ($branchIndex -ge 0 -and $branchIndex -lt $branches.Count) {
                $selectedBranch = $branches[$branchIndex].name
                Write-Log -Message "Selected branch: $selectedBranch" -Level "Success"
                Write-Host "✅ Selected branch: $selectedBranch" -ForegroundColor Green
                return $selectedBranch
            }
            else {
                Write-Host "❌ Invalid selection. Using default branch: $($Repository.default_branch)" -ForegroundColor Yellow
                return $Repository.default_branch
            }
        }
        catch {
            Write-Host "❌ Invalid input. Using default branch: $($Repository.default_branch)" -ForegroundColor Yellow
            return $Repository.default_branch
        }
    }
    catch {
        Write-Log -Message "Failed to fetch branches: $($_.Exception.Message)" -Level "Warning"
        Write-Host "⚠️  Could not fetch branches. Using default: $($Repository.default_branch)" -ForegroundColor Yellow
        return $Repository.default_branch
    }
}

function Invoke-GitHubRepositorySelection {
    <#
    .SYNOPSIS
        Complete GitHub repository selection workflow.
    
    .DESCRIPTION
        This function provides the complete workflow for GitHub repository selection:
        - Token acquisition and validation
        - Repository fetching and display
        - User selection interface
        - Branch selection
        - Manual entry fallback
    
    .OUTPUTS
        Returns a hashtable with RepoUrl, Branch, and Token information.
    #>
    [CmdletBinding()]
    param()
    
    Write-Log -Message "Starting GitHub repository selection workflow" -Level "Info"
    
    # Get GitHub token
    $token = Get-GitHubTokenFromUser
    if (-not $token) {
        Write-Host "⚠️  Proceeding without GitHub integration." -ForegroundColor Yellow
        return @{
            RepoUrl = $null
            Branch = $null
            Token = $null
            Manual = $true
        }
    }
    
    # Fetch repositories
    $repositories = Get-GitHubRepositories -Token $token -IncludeOrganization
    if (-not $repositories -or $repositories.Count -eq 0) {
        Write-Host "❌ No repositories found. You may need to check your token permissions." -ForegroundColor Red
        return @{
            RepoUrl = $null
            Branch = $null
            Token = $token
            Manual = $true
        }
    }
    
    # Select repository
    $selectedRepo = Select-GitHubRepository -Repositories $repositories
    if (-not $selectedRepo) {
        Write-Log -Message "Repository selection cancelled" -Level "Info"
        return @{
            RepoUrl = $null
            Branch = $null
            Token = $token
            Cancelled = $true
        }
    }
    
    if ($selectedRepo.Manual) {
        Write-Log -Message "Manual repository entry selected" -Level "Info"
        return @{
            RepoUrl = $null
            Branch = $null
            Token = $token
            Manual = $true
        }
    }
    
    # Select branch
    $selectedBranch = Select-GitHubBranch -Repository $selectedRepo -Token $token
    
    # Return complete selection
    return @{
        RepoUrl = $selectedRepo.clone_url
        Branch = $selectedBranch
        Token = $token
        Repository = $selectedRepo
    }
}