function Select-GitHubRepository {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Filter,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('all', 'owner', 'public', 'private', 'member')]
        [string]$Type = 'owner',
        
        [Parameter(Mandatory = $false)]
        [string]$Language
    )
    
    try {
        # Get repositories
        $params = @{
            Type = $Type
        }
        if ($Language) { $params.Language = $Language }
        
        $repositories = Get-GitHubRepositories @params
        
        if (-not $repositories -or $repositories.Count -eq 0) {
            Write-Host "No repositories found matching the criteria." -ForegroundColor Yellow
            return $null
        }
        
        # Apply filter if specified
        if ($Filter) {
            $repositories = $repositories | Where-Object {
                $_.Name -like "*$Filter*" -or 
                $_.Description -like "*$Filter*" -or
                $_.FullName -like "*$Filter*"
            }
            
            if (-not $repositories -or $repositories.Count -eq 0) {
                Write-Host "No repositories found matching filter '$Filter'." -ForegroundColor Yellow
                return $null
            }
        }
        
        # Sort repositories by name for consistent display
        $repositories = $repositories | Sort-Object Name
        
        Write-Host ""
        Write-Host "=== Select GitHub Repository ===" -ForegroundColor Cyan
        Write-Host ""
        
        # Display repositories with numbers
        for ($i = 0; $i -lt $repositories.Count; $i++) {
            $repo = $repositories[$i]
            $number = ($i + 1).ToString().PadLeft(2)
            
            # Format repository info
            $visibility = if ($repo.Private) { "Private" } else { "Public" }
            $language = if ($repo.Language) { $repo.Language } else { "N/A" }
            $description = if ($repo.Description) { 
                if ($repo.Description.Length -gt 60) {
                    $repo.Description.Substring(0, 57) + "..."
                } else {
                    $repo.Description
                }
            } else { 
                "No description" 
            }
            
            Write-Host "$number. " -ForegroundColor Yellow -NoNewline
            Write-Host "$($repo.Name)" -ForegroundColor White -NoNewline
            Write-Host " ($visibility, $language)" -ForegroundColor Gray
            Write-Host "    $description" -ForegroundColor Gray
            
            # Show additional info for important repos
            if ($repo.StargazersCount -gt 0 -or $repo.ForksCount -gt 0) {
                $stats = @()
                if ($repo.StargazersCount -gt 0) { $stats += "Stars: $($repo.StargazersCount)" }
                if ($repo.ForksCount -gt 0) { $stats += "Forks: $($repo.ForksCount)" }
                Write-Host "    $($stats -join ' | ')" -ForegroundColor DarkGray
            }
            
            Write-Host ""
        }
        
        # Add options for refresh and cancel
        $refreshOption = $repositories.Count + 1
        $cancelOption = $repositories.Count + 2
        
        Write-Host "$refreshOption. " -ForegroundColor Cyan -NoNewline
        Write-Host "Refresh repository list" -ForegroundColor Cyan
        Write-Host "$cancelOption. " -ForegroundColor Red -NoNewline
        Write-Host "Cancel" -ForegroundColor Red
        Write-Host ""
        
        # Get user selection
        do {
            $selection = Read-Host "Select a repository (1-$($repositories.Count), $refreshOption for refresh, $cancelOption to cancel)"
            
            if ($selection -eq $cancelOption -or $selection -eq 'q' -or $selection -eq 'quit' -or $selection -eq 'cancel') {
                Write-Host "Selection cancelled." -ForegroundColor Yellow
                return $null
            }
            
            if ($selection -eq $refreshOption -or $selection -eq 'r' -or $selection -eq 'refresh') {
                Write-Host "Refreshing repository list..." -ForegroundColor Yellow
                return Select-GitHubRepository -Filter $Filter -Type $Type -Language $Language
            }
            
            $selectionNum = $null
            if ([int]::TryParse($selection, [ref]$selectionNum)) {
                if ($selectionNum -ge 1 -and $selectionNum -le $repositories.Count) {
                    $selectedRepo = $repositories[$selectionNum - 1]
                    
                    # Display selection confirmation
                    Write-Host ""
                    Write-Host "SUCCESS: Selected repository:" -ForegroundColor Green
                    Write-Host "  Name: $($selectedRepo.Name)" -ForegroundColor White
                    Write-Host "  Full Name: $($selectedRepo.FullName)" -ForegroundColor Gray
                    Write-Host "  Description: $($selectedRepo.Description)" -ForegroundColor Gray
                    Write-Host "  Language: $($selectedRepo.Language)" -ForegroundColor Gray
                    Write-Host "  Visibility: $(if ($selectedRepo.Private) { 'Private' } else { 'Public' })" -ForegroundColor Gray
                    Write-Host "  Clone URL: $($selectedRepo.CloneUrl)" -ForegroundColor Gray
                    Write-Host ""
                    
                    # Store selection in configuration
                    Set-GitHubConfiguration -SelectedRepository $selectedRepo
                    
                    Write-Host "Repository selection saved. You can now use:" -ForegroundColor Cyan
                    Write-Host "  - Deploy-GitHubRepository    - Deploy this repository" -ForegroundColor Gray
                    Write-Host "  - Clone-GitHubRepository     - Clone this repository locally" -ForegroundColor Gray
                    
                    return $selectedRepo
                }
            }
            
            Write-Host "Invalid selection. Please enter a number between 1 and $($repositories.Count), $refreshOption for refresh, or $cancelOption to cancel." -ForegroundColor Red
            
        } while ($true)
    }
    catch {
        Write-Error "Failed to select GitHub repository: $($_.Exception.Message)"
        return $null
    }
}
