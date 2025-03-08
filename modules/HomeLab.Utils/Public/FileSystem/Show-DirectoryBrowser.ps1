function Show-DirectoryBrowser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$InitialDirectory = (Get-Location),
        
        [Parameter(Mandatory = $false)]
        [string]$Title = "Select a directory",
        
        [Parameter(Mandatory = $false)]
        [switch]$SelectFile,
        
        [Parameter(Mandatory = $false)]
        [string]$FileFilter = "*",
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowHidden,
        
        [Parameter(Mandatory = $false)]
        [switch]$AllowDirectoryForFiles
    )
    
    begin {
        # Function to get items with paging support
        function Get-DirectoryItems {
            param (
                [string]$Path,
                [string]$FileFilter = "*",
                [switch]$ShowHidden
            )
            
            $dirParams = @{
                Path = $Path
                Directory = $true
            }
            
            if ($ShowHidden) {
                $dirParams.Force = $true
            }
            
            $directories = @(Get-ChildItem @dirParams | Sort-Object Name)
            
            $files = @()
            if ($SelectFile) {
                $fileParams = @{
                    Path = $Path
                    File = $true
                    Filter = $FileFilter
                }
                
                if ($ShowHidden) {
                    $fileParams.Force = $true
                }
                
                $files = @(Get-ChildItem @fileParams | Sort-Object Name)
            }
            
            return @{
                Directories = $directories
                Files = $files
            }
        }
    }
    
    process {
        $currentPath = $InitialDirectory
        $selectedPath = $null
        $exit = $false
        $page = 1
        $itemsPerPage = 15
        $showPageInfo = $false
        
        while (-not $exit) {
            Clear-Host
            Write-Host "=== $Title ===" -ForegroundColor Cyan
            Write-Host "Current location: $currentPath" -ForegroundColor Yellow
            Write-Host ""
            
            # Get directories and files
            $items = Get-DirectoryItems -Path $currentPath -FileFilter $FileFilter -ShowHidden:$ShowHidden
            $directories = $items.Directories
            $files = $items.Files
            
            # Calculate total pages
            $totalItems = $directories.Count
            if ($SelectFile) {
                $totalItems += $files.Count
            }
            
            $totalPages = [Math]::Ceiling($totalItems / $itemsPerPage)
            if ($totalPages -eq 0) { $totalPages = 1 }
            
            # Ensure page is within bounds
            if ($page -lt 1) { $page = 1 }
            if ($page -gt $totalPages) { $page = $totalPages }
            
            # Calculate start and end indices for current page
            $startIndex = ($page - 1) * $itemsPerPage
            $endIndex = [Math]::Min($startIndex + $itemsPerPage - 1, $totalItems - 1)
            
            # Show page info if needed
            if ($showPageInfo -or $totalPages -gt 1) {
                Write-Host "Page $page of $totalPages" -ForegroundColor Magenta
                Write-Host ""
            }
            
            # Add parent directory option
            Write-Host "0: [..] Parent Directory" -ForegroundColor Magenta
            
            # List directories and files for current page
            $itemIndex = 0
            $displayIndex = 1
            
            # List directories
            foreach ($dir in $directories) {
                if ($itemIndex -ge $startIndex -and $itemIndex -le $endIndex) {
                    Write-Host "$displayIndex`: [DIR] $($dir.Name)" -ForegroundColor Green
                    $displayIndex++
                }
                $itemIndex++
                
                # Break if we've displayed all items for this page
                if ($itemIndex -gt $endIndex) { break }
            }
            
            # List files if selecting a file
            if ($SelectFile -and $itemIndex -le $endIndex) {
                foreach ($file in $files) {
                    if ($itemIndex -ge $startIndex -and $itemIndex -le $endIndex) {
                        Write-Host "$displayIndex`: [FILE] $($file.Name)" -ForegroundColor White
                        $displayIndex++
                    }
                    $itemIndex++
                    
                    # Break if we've displayed all items for this page
                    if ($itemIndex -gt $endIndex) { break }
                }
            }
            
            Write-Host ""
            Write-Host "Navigation Commands:" -ForegroundColor Yellow
            
            # Show "Confirm current directory" option based on mode
            if (-not $SelectFile -or ($SelectFile -and $AllowDirectoryForFiles)) {
                Write-Host "C: Confirm current directory" -ForegroundColor Yellow
                
                # If in file selection mode with directory allowed, show what will happen
                if ($SelectFile -and $AllowDirectoryForFiles) {
                    $ps1Count = (Get-ChildItem -Path $currentPath -Filter "*.ps1" -File).Count
                    Write-Host "   (Will process all $ps1Count PowerShell scripts in this directory)" -ForegroundColor Gray
                }
            }
            
            if ($totalPages -gt 1) {
                Write-Host "N: Next page" -ForegroundColor Yellow
                Write-Host "P: Previous page" -ForegroundColor Yellow
            }
            
            Write-Host "Q: Quit" -ForegroundColor Red
            Write-Host ""
            
            $choice = Read-Host "Enter your choice"
            
            switch ($choice.ToUpper()) {
                "0" {
                    # Navigate to parent directory
                    $parentPath = Split-Path -Path $currentPath -Parent
                    if ($parentPath) {
                        $currentPath = $parentPath
                        $page = 1  # Reset to first page when changing directories
                    }
                    else {
                        Write-Host "Already at the root directory." -ForegroundColor Red
                        Start-Sleep -Seconds 1
                    }
                }
                "C" {
                    # Confirm current directory
                    if (-not $SelectFile -or ($SelectFile -and $AllowDirectoryForFiles)) {
                        $selectedPath = $currentPath
                        $exit = $true
                    }
                    else {
                        Write-Host "In file selection mode, please select a file instead." -ForegroundColor Yellow
                        Start-Sleep -Seconds 2
                    }
                }
                "N" {
                    # Next page
                    if ($page -lt $totalPages) {
                        $page++
                    }
                    else {
                        Write-Host "Already on the last page." -ForegroundColor Red
                        Start-Sleep -Seconds 1
                    }
                }
                "P" {
                    # Previous page
                    if ($page -gt 1) {
                        $page--
                    }
                    else {
                        Write-Host "Already on the first page." -ForegroundColor Red
                        Start-Sleep -Seconds 1
                    }
                }
                "Q" {
                    # Quit
                    return $null
                }
                default {
                    # Try to parse as number
                    if ([int]::TryParse($choice, [ref]$null)) {
                        $index = [int]::Parse($choice) - 1
                        $pageOffset = ($page - 1) * $itemsPerPage
                        $actualIndex = $index + $pageOffset
                        
                        if ($index -ge 0) {
                            # Check if it's a directory
                            if ($actualIndex -lt $directories.Count) {
                                # Navigate to selected directory
                                $currentPath = $directories[$actualIndex].FullName
                                $page = 1  # Reset to first page when changing directories
                            }
                            # Check if it's a file and file selection is enabled
                            elseif ($SelectFile -and $actualIndex -lt ($directories.Count + $files.Count)) {
                                # Select file
                                $fileIndex = $actualIndex - $directories.Count
                                if ($fileIndex -ge 0 -and $fileIndex -lt $files.Count) {
                                    $selectedPath = $files[$fileIndex].FullName
                                    $exit = $true
                                }
                                else {
                                    Write-Host "Invalid file selection." -ForegroundColor Red
                                    Start-Sleep -Seconds 1
                                }
                            }
                            else {
                                Write-Host "Invalid selection." -ForegroundColor Red
                                Start-Sleep -Seconds 1
                            }
                        }
                        else {
                            Write-Host "Invalid selection." -ForegroundColor Red
                            Start-Sleep -Seconds 1
                        }
                    }
                    else {
                        Write-Host "Invalid input. Please enter a number or command." -ForegroundColor Red
                        Start-Sleep -Seconds 1
                    }
                }
            }
        }
        
        return $selectedPath
    }
}
