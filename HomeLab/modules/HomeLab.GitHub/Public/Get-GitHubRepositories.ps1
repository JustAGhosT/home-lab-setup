function Get-GitHubRepositories {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('all', 'owner', 'public', 'private', 'member')]
        [string]$Type = 'owner',
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('created', 'updated', 'pushed', 'full_name')]
        [string]$Sort = 'updated',
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('asc', 'desc')]
        [string]$Direction = 'desc',
        
        [Parameter(Mandatory = $false)]
        [string]$Language,
        
        [Parameter(Mandatory = $false)]
        [switch]$Archived,
        
        [Parameter(Mandatory = $false)]
        [switch]$Fork,
        
        [Parameter(Mandatory = $false)]
        [int]$Limit = 100
    )
    
    try {
        # Test connection first
        if (-not (Test-GitHubConnection -Quiet)) {
            throw "Not connected to GitHub. Please run Connect-GitHub first."
        }
        
        Write-Host "Fetching GitHub repositories..." -ForegroundColor Yellow
        
        # Build query parameters
        $queryParams = @()
        $queryParams += "type=$Type"
        $queryParams += "sort=$Sort"
        $queryParams += "direction=$Direction"
        $queryParams += "per_page=$([Math]::Min($Limit, 100))"
        
        $queryString = $queryParams -join '&'
        $endpoint = "/user/repos?$queryString"
        
        # Get repositories
        $repos = Invoke-GitHubApi -Endpoint $endpoint -Method GET
        
        if (-not $repos) {
            Write-Host "No repositories found." -ForegroundColor Yellow
            return @()
        }
        
        # Apply additional filters
        $filteredRepos = $repos
        
        # Filter by language if specified
        if ($Language) {
            $filteredRepos = $filteredRepos | Where-Object { $_.language -eq $Language }
        }
        
        # Filter archived repositories
        if (-not $Archived) {
            $filteredRepos = $filteredRepos | Where-Object { -not $_.archived }
        }
        
        # Filter fork repositories
        if (-not $Fork) {
            $filteredRepos = $filteredRepos | Where-Object { -not $_.fork }
        }
        
        # Create simplified repository objects
        $repositories = $filteredRepos | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.name
                FullName = $_.full_name
                Description = $_.description
                Language = $_.language
                Private = $_.private
                Fork = $_.fork
                Archived = $_.archived
                DefaultBranch = $_.default_branch
                CloneUrl = $_.clone_url
                SshUrl = $_.ssh_url
                HtmlUrl = $_.html_url
                CreatedAt = $_.created_at
                UpdatedAt = $_.updated_at
                PushedAt = $_.pushed_at
                Size = $_.size
                StargazersCount = $_.stargazers_count
                ForksCount = $_.forks_count
                OpenIssuesCount = $_.open_issues_count
                Topics = $_.topics
                Visibility = $_.visibility
                Owner = $_.owner.login
            }
        }
        
        Write-Host "SUCCESS: Found $($repositories.Count) repositories" -ForegroundColor Green
        
        if ($repositories.Count -gt 0) {
            # Display summary
            $publicCount = ($repositories | Where-Object { -not $_.Private }).Count
            $privateCount = ($repositories | Where-Object { $_.Private }).Count
            
            Write-Host ""
            Write-Host "Repository Summary:" -ForegroundColor Cyan
            Write-Host "  Public: $publicCount" -ForegroundColor Gray
            Write-Host "  Private: $privateCount" -ForegroundColor Gray
        }
        
        return $repositories
    }
    catch {
        Write-Error "Failed to retrieve GitHub repositories: $($_.Exception.Message)"
        return @()
    }
}
