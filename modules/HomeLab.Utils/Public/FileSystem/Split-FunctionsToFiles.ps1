function Split-FunctionsToFiles {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Standard')]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ParameterSetName = 'Standard')]
        [string]$Path,
        
        [Parameter(Mandatory = $false, ParameterSetName = 'Standard')]
        [string]$OutputDirectory,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeComments,
        
        [Parameter(Mandatory = $false)]
        [string]$Prefix = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Suffix = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'Interactive')]
        [switch]$Interactive
    )
    
    process {
        $totalSuccessCount = 0
        $processedFiles = 0
        
        # Interactive mode - select input file or directory
        if ($Interactive -or [string]::IsNullOrEmpty($Path)) {
            Write-Host "Please select a PowerShell script file or directory containing scripts." -ForegroundColor Cyan
            
            # Use Show-DirectoryBrowser with AllowDirectoryForFiles switch
            $selectedPath = Show-DirectoryBrowser -Title "Select PowerShell Script File" -SelectFile -FileFilter "*.ps1" -AllowDirectoryForFiles
            
            if ($null -eq $selectedPath -or [string]::IsNullOrEmpty($selectedPath)) {
                Write-Warning "Operation cancelled by user or no selection made."
                return
            }
            
            $Path = $selectedPath
        }
        
        # Determine if the path is a file or directory
        $isDirectory = Test-Path -Path $Path -PathType Container
        $isFile = Test-Path -Path $Path -PathType Leaf
        
        if (-not $isDirectory -and -not $isFile) {
            Write-Error "The specified path '$Path' does not exist."
            return
        }
        
        # Interactive mode - select output directory if not specified
        if ($Interactive -or [string]::IsNullOrEmpty($OutputDirectory)) {
            # Get parent directory for initial directory
            $initialDir = if ($isFile) {
                Split-Path -Parent $Path
            } else {
                $Path
            }
            
            Write-Host "Please select the output directory for the split function files." -ForegroundColor Cyan
            $selectedDir = Show-DirectoryBrowser -Title "Select Output Directory" -InitialDirectory $initialDir
            
            if ($null -eq $selectedDir -or [string]::IsNullOrEmpty($selectedDir)) {
                Write-Warning "Operation cancelled by user or no directory selected."
                return
            }
            
            $OutputDirectory = $selectedDir
        }
        
        # Create output directory if it doesn't exist
        if (-not (Test-Path -Path $OutputDirectory -PathType Container)) {
            if ($PSCmdlet.ShouldProcess($OutputDirectory, "Create directory")) {
                try {
                    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
                    Write-Verbose "Created output directory: $OutputDirectory"
                }
                catch {
                    Write-Error "Failed to create output directory '$OutputDirectory': $_"
                    return
                }
            }
        }
        
        # Process files
        if ($isDirectory) {
            # Process all PS1 files in the directory
            $scriptFiles = Get-ChildItem -Path $Path -Filter "*.ps1" -File
            
            if ($scriptFiles.Count -eq 0) {
                Write-Warning "No PowerShell script files found in directory: $Path"
                return
            }
            
            Write-Host "Processing $($scriptFiles.Count) PowerShell script files..." -ForegroundColor Yellow
            
            foreach ($scriptFile in $scriptFiles) {
                $processedFiles++
                
                $splitParams = @{
                    ScriptPath = $scriptFile.FullName
                    OutputDir = $OutputDirectory
                    IncludeComments = $IncludeComments
                    Prefix = $Prefix
                    Suffix = $Suffix
                    Force = $Force
                }
                
                $fileSuccessCount = Split-SinglePSFile @splitParams
                $totalSuccessCount += $fileSuccessCount
                
                Write-Host "[$processedFiles/$($scriptFiles.Count)] Processed $($scriptFile.Name): Extracted $fileSuccessCount functions" -ForegroundColor Cyan
            }
        }
        else {
            # Process single file
            $splitParams = @{
                ScriptPath = $Path
                OutputDir = $OutputDirectory
                IncludeComments = $IncludeComments
                Prefix = $Prefix
                Suffix = $Suffix
                Force = $Force
            }
            
            $totalSuccessCount = Split-SinglePSFile @splitParams
            $processedFiles = 1
        }
        
        if ($totalSuccessCount -gt 0) {
            Write-Host "Completed processing $processedFiles file(s)" -ForegroundColor Green
            Write-Host "Created $totalSuccessCount function files in $OutputDirectory" -ForegroundColor Green
        }
        else {
            Write-Warning "No function files were created."
        }
    }
}
