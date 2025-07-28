function Clone-GitHubRepository {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [object]$Repository,
        
        [Parameter(Mandatory = $false)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$Branch,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    try {
        # Determine which repository to clone
        $repoToClone = $null
        
        if ($Repository) {
            if ($Repository -is [string]) {
                # Repository specified as string (owner/repo)
                Write-Host "Getting repository information for '$Repository'..." -ForegroundColor Yellow
                $repoInfo = Invoke-GitHubApi -Endpoint "/repos/$Repository" -Method GET
                $repoToClone = [PSCustomObject]@{
                    Name          = $repoInfo.name
                    FullName      = $repoInfo.full_name
                    CloneUrl      = $repoInfo.clone_url
                    SshUrl        = $repoInfo.ssh_url
                    DefaultBranch = $repoInfo.default_branch
                    Private       = $repoInfo.private
                }
            }
            else {
                # Repository specified as object
                $repoToClone = $Repository
            }
        }
        else {
            # Use selected repository
            $config = Get-GitHubConfiguration
            if ($config.SelectedRepository) {
                $repoToClone = $config.SelectedRepository
                Write-Host "Using selected repository: $($repoToClone.FullName)" -ForegroundColor Gray
            }
            else {
                throw "No repository specified and no repository selected. Use Select-GitHubRepository first or specify -Repository parameter."
            }
        }
        
        if (-not $repoToClone) {
            throw "Could not determine repository to clone."
        }
        
        # Determine clone path
        if (-not $Path) {
            $config = Get-GitHubConfiguration
            $basePath = $config.DefaultClonePath
            $Path = Join-Path $basePath $repoToClone.Name
        }
        
        # Ensure parent directory exists
        $parentPath = Split-Path $Path -Parent
        if (-not (Test-Path $parentPath)) {
            Write-Host "Creating directory: $parentPath" -ForegroundColor Yellow
            New-Item -ItemType Directory -Path $parentPath -Force | Out-Null
        }
        
        # Check if directory already exists
        if (Test-Path $Path) {
            if ($Force) {
                Write-Host "Removing existing directory: $Path" -ForegroundColor Yellow
                Remove-Item -Path $Path -Recurse -Force
            }
            else {
                throw "Directory already exists: $Path. Use -Force to overwrite."
            }
        }
        
        # Check if git is available
        $gitPath = Get-Command git -ErrorAction SilentlyContinue
        if (-not $gitPath) {
            throw "Git is not installed or not in PATH. Please install Git and try again."
        }
        
        Write-Host "Cloning repository..." -ForegroundColor Yellow
        Write-Host "  Repository: $($repoToClone.FullName)" -ForegroundColor Gray
        Write-Host "  Destination: $Path" -ForegroundColor Gray
        
        # Determine clone URL (prefer HTTPS for simplicity)
        $cloneUrl = $repoToClone.CloneUrl
        
        # Build git clone command
        $gitArgs = @('clone', $cloneUrl, $Path)
        
        # Add branch if specified
        if ($Branch) {
            $gitArgs = @('clone', '--branch', $Branch, $cloneUrl, $Path)
            Write-Host "  Branch: $Branch" -ForegroundColor Gray
        }
        else {
            Write-Host "  Branch: $($repoToClone.DefaultBranch) (default)" -ForegroundColor Gray
        }
        
        # Execute git clone
        $process = Start-Process -FilePath 'git' -ArgumentList $gitArgs -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Host "SUCCESS: Repository cloned successfully!" -ForegroundColor Green
            Write-Host "  Location: $Path" -ForegroundColor Gray
            
            # Get some info about the cloned repository
            $locationPushed = $false
            try {
                Push-Location $Path
                $locationPushed = $true
                $currentBranch = (git branch --show-current 2>$null).Trim()
                $lastCommit = (git log -1 --format="%h %s" 2>$null).Trim()
                Pop-Location
                $locationPushed = $false

                if ($currentBranch) {
                    Write-Host "  Current branch: $currentBranch" -ForegroundColor Gray
                }
                if ($lastCommit) {
                    Write-Host "  Last commit: $lastCommit" -ForegroundColor Gray
                }
            }
            catch {
                # Clean up location stack if we pushed but haven't popped yet
                if ($locationPushed) {
                    try {
                        Pop-Location
                    }
                    catch {
                        Write-Verbose "Failed to pop location during error cleanup: $($_.Exception.Message)"
                    }
                }
                Write-Verbose "Could not get git info: $($_.Exception.Message)"
            }
            
            return $Path
        }
        else {
            throw "Git clone failed with exit code $($process.ExitCode)"
        }
    }
    catch {
        Write-Error "Failed to clone GitHub repository: $($_.Exception.Message)"
        return $null
    }
}
