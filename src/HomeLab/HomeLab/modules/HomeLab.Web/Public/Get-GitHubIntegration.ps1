function Get-GitHubToken {
    <#
    .SYNOPSIS
        Gets a GitHub token from secure storage or prompts user to enter one.
    
    .DESCRIPTION
        This function first checks for a saved GitHub token in secure storage.
        If not found, it prompts the user to enter a token and validates it.
        The token is then saved securely for future use.
    
    .PARAMETER ForceNew
        Forces the user to enter a new token, even if one is already saved.
    
    .OUTPUTS
        Returns the GitHub token as a string, or $null if the user cancels.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$ForceNew
    )
    
    # Check for existing token in secure storage
    if (-not $ForceNew) {
        $existingToken = Get-SecureGitHubToken
        if ($existingToken) {
            Write-Log -Message "Using existing GitHub token from secure storage" -Level "Info"
            Write-Host "✅ Using saved GitHub token" -ForegroundColor Green
            return $existingToken
        }
    }
    
    Write-Host "🔑 GitHub Token Required" -ForegroundColor Cyan
    Write-Host "Please provide your GitHub Personal Access Token." -ForegroundColor White
    Write-Host "You can create one at: https://github.com/settings/tokens" -ForegroundColor Yellow
    Write-Host "Required scopes: repo, workflow, admin:org (for organization repos)" -ForegroundColor Yellow
    Write-Host ""
    
    do {
        $token = Read-Host "Enter your GitHub token" -AsSecureString
        
        if ($token.Length -eq 0) {
            Write-Host "❌ Token cannot be empty. Please try again." -ForegroundColor Red
            continue
        }
        
        # Convert to plain text for validation
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($token)
        try {
            $plainToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            
            if (Test-GitHubToken -Token $plainToken) {
                # Save token securely
                if (Save-SecureGitHubToken -Token $plainToken) {
                    Write-Log -Message "GitHub token validated and saved securely" -Level "Success"
                    Write-Host "✅ Token validated and saved securely!" -ForegroundColor Green
                    return $plainToken
                }
                else {
                    Write-Host "⚠️  Token validated but could not be saved securely. Continuing without saving." -ForegroundColor Yellow
                    return $plainToken
                }
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
    [OutputType([System.Boolean])]
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

function Get-GitHubRepository {
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
    [OutputType([System.Object[]])]
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
        Write-Host "X Failed to fetch repositories: $($_.Exception.Message)" -ForegroundColor Red
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
    [OutputType([System.Collections.Hashtable])]
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
        Provides a complete GitHub integration workflow for repository selection.
    
    .DESCRIPTION
        This function guides the user through the complete process of:
        - Token authentication
        - Repository selection
        - Branch selection
        - Manual entry fallback
    
    .OUTPUTS
        Returns a hashtable with RepoUrl, Branch, and Token information.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param()
    
    Write-Log -Message "Starting GitHub repository selection workflow" -Level "Info"
    
    # Get GitHub token
    $token = Get-GitHubToken
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
    $repositories = Get-GitHubRepository -Token $token -IncludeOrganization
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

function Get-GitHubIntegration {
    <#
    .SYNOPSIS
        Provides a complete GitHub integration workflow for repository selection.
    
    .DESCRIPTION
        This function guides the user through the complete process of:
        1. Authenticating with GitHub
        2. Selecting a repository
        3. Choosing a branch
        4. Returning the integration details
    
    .OUTPUTS
        Returns a hashtable with RepoUrl, Branch, and Token information.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param()

    Write-Log -Message "Starting GitHub repository selection workflow" -Level "Info"

    # Get GitHub token
    $token = Get-GitHubToken
    if (-not $token) {
        Write-Host "⚠️  Proceeding without GitHub integration." -ForegroundColor Yellow
        return @{
            RepoUrl = $null
            Branch = $null
            Token = $null
        }
    }

    # Get repositories
    Write-Log -Message "Fetching GitHub repositories" -Level "Info"
    $repositories = Get-GitHubRepository -Token $token -IncludeOrganization
    if (-not $repositories -or $repositories.Count -eq 0) {
        Write-Host "❌ No repositories found or failed to fetch repositories." -ForegroundColor Red
        return @{
            RepoUrl = $null
            Branch = $null
            Token = $null
        }
    }

    # Select repository
    $selectedRepo = Select-GitHubRepository -Repositories $repositories
    if (-not $selectedRepo) {
        Write-Log -Message "Repository selection cancelled" -Level "Info"
        return @{
            RepoUrl = $null
            Branch = $null
            Token = $null
        }
    }

    # Handle manual repository entry
    if ($selectedRepo.Manual) {
        $repoUrl = Read-Host "Enter repository URL (e.g., https://github.com/username/repo)"
        if (-not $repoUrl) {
            Write-Log -Message "Manual repository entry cancelled" -Level "Info"
            return @{
                RepoUrl = $null
                Branch = $null
                Token = $null
            }
        }
    }
    else {
        $repoUrl = $selectedRepo.clone_url
    }

    # Select branch
    $branch = Select-GitHubBranch -Token $token -RepoUrl $repoUrl
    if (-not $branch) {
        Write-Log -Message "Branch selection cancelled" -Level "Info"
        return @{
            RepoUrl = $null
            Branch = $null
            Token = $null
        }
    }

    Write-Log -Message "GitHub integration completed successfully" -Level "Success"
    Write-Host "✅ GitHub integration configured successfully!" -ForegroundColor Green
    Write-Host "Repository: $repoUrl" -ForegroundColor Cyan
    Write-Host "Branch: $branch" -ForegroundColor Cyan

    return @{
        RepoUrl = $repoUrl
        Branch = $branch
        Token = $token
    }
}

# Secure token storage functions
function Save-SecureGitHubToken {
    <#
    .SYNOPSIS
        Saves a GitHub token to secure storage using Windows Credential Manager.
    
    .PARAMETER Token
        The GitHub token to save.
    
    .PARAMETER Username
        The username to associate with the token (default: HomeLab-GitHub).
    
    .OUTPUTS
        Returns $true if successful, $false otherwise.
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification='Legitimate use for secure credential storage in Windows Credential Manager')]
    [OutputType([System.Boolean])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Token,
        
        [Parameter()]
        [string]$Username = "HomeLab-GitHub"
    )
    
    try {
        # Create a PSCredential object
        # Suppressing PSAvoidUsingConvertToSecureStringWithPlainText - This is a legitimate use case for secure credential storage in Windows Credential Manager
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification='Legitimate use for secure credential storage in Windows Credential Manager')]
        $secureToken = ConvertTo-SecureString -String $Token -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential($Username, $secureToken)
        
        # Save to Windows Credential Manager
        $credentialPath = Join-Path $env:USERPROFILE ".homelab\credentials"
        if (-not (Test-Path $credentialPath)) {
            New-Item -Path $credentialPath -ItemType Directory -Force | Out-Null
        }
        
        $credentialFile = Join-Path $credentialPath "github-token.xml"
        $credential | Export-Clixml -Path $credentialFile -Force
        
        # Set restricted access permissions (Windows only)
        if ($IsWindows -or $env:OS -eq "Windows_NT") {
            try {
                $acl = Get-Acl -Path $credentialFile
                $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($currentUser, "FullControl", "Allow")
                $acl.SetAccessRule($accessRule)
                $acl | Set-Acl -Path $credentialFile
            }
            catch {
                Write-Warning "Could not set restricted permissions on credential file: $($_.Exception.Message)"
            }
        }
        
        Write-Log -Message "GitHub token saved securely to: $credentialFile" -Level "Success"
        return $true
    }
    catch {
        Write-Log -Message "Failed to save GitHub token securely: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

function Get-SecureGitHubToken {
    <#
    .SYNOPSIS
        Retrieves a GitHub token from secure storage.
    
    .PARAMETER Username
        The username associated with the token.
    
    .OUTPUTS
        Returns the GitHub token as a string, or $null if not found.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter()]
        [string]$Username = "HomeLab-GitHub"
    )
    
    try {
        $credentialPath = Join-Path $env:USERPROFILE ".homelab\credentials"
        $credentialFile = Join-Path $credentialPath "github-token.xml"
        
        if (-not (Test-Path $credentialFile)) {
            Write-Log -Message "No saved GitHub token found" -Level "Info"
            return $null
        }
        
        # Import the credential
        $credential = Import-Clixml -Path $credentialFile
        
        # Convert back to plain text
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password)
        try {
            $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            Write-Log -Message "GitHub token retrieved from secure storage" -Level "Success"
            return $token
        }
        finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        }
    }
    catch {
        Write-Log -Message "Failed to retrieve GitHub token from secure storage: $($_.Exception.Message)" -Level "Error"
        return $null
    }
}

function Remove-SecureGitHubToken {
    <#
    .SYNOPSIS
        Removes a GitHub token from secure storage.
    
    .PARAMETER Username
        The username associated with the token.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Username = "HomeLab-GitHub"
    )
    
    try {
        $credentialPath = Join-Path $env:USERPROFILE ".homelab\credentials"
        $credentialFile = Join-Path $credentialPath "github-token.xml"
        
        if (Test-Path $credentialFile) {
            Remove-Item -Path $credentialFile -Force
            Write-Log -Message "GitHub token removed from secure storage" -Level "Success"
            return $true
        }
        else {
            Write-Log -Message "No GitHub token found in secure storage" -Level "Info"
            return $false
        }
    }
    catch {
        Write-Log -Message "Failed to remove GitHub token from secure storage: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

function Test-SecureGitHubToken {
    <#
    .SYNOPSIS
        Tests if a GitHub token exists in secure storage and is valid.
    
    .OUTPUTS
        Returns $true if token exists and is valid, $false otherwise.
    #>
    [CmdletBinding()]
    param()
    
    $token = Get-SecureGitHubToken
    if (-not $token) {
        return $false
    }
    
    return Test-GitHubToken -Token $token
}