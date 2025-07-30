# Enhanced Markdown Linter Pre-commit Hook (PowerShell)
# Automatically fixes markdown issues and re-stages files
[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Files
)

# Set error action preference
$ErrorActionPreference = "Continue"

# Get the script directory and repository root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = & git rev-parse --show-toplevel

# Validate prerequisites
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "Python is not available in PATH"
    exit 1
}

if (-not (Test-Path "$ScriptDir\__main__.py")) {
    Write-Error "Markdown linter not found at expected location"
    exit 1
}

# Change to markdown linter directory
Set-Location $ScriptDir

# Initialize tracking variables
$ModifiedFiles = @()
$FilesProcessed = 0

Write-Host "Enhanced Markdown Linter - Pre-commit Hook" -ForegroundColor Green
Write-Host "Processing $($Files.Count) markdown file(s)..." -ForegroundColor Cyan

# Process each file
foreach ($File in $Files) {
    # Resolve the full path relative to repo root
    $FullPath = if ([System.IO.Path]::IsPathRooted($File)) {
        $File
    }
    else {
        Join-Path $RepoRoot $File
    }

    if (-not (Test-Path $FullPath)) {
        Write-Warning "File not found: $File"
        continue
    }

    Write-Host "Checking: $File" -ForegroundColor Yellow

    # Get file hash before processing
    $BeforeHash = (Get-FileHash $FullPath -Algorithm MD5).Hash

    # Run markdown linter with --fix (use full path)
    try {
        $Result = & python __main__.py $FullPath --fix 2>&1

        if ($LASTEXITCODE -eq 0) {
            # Get file hash after processing
            $AfterHash = (Get-FileHash $FullPath -Algorithm MD5).Hash

            # Check if file was actually modified
            if ($BeforeHash -ne $AfterHash) {
                Write-Host "  → File modified and fixed" -ForegroundColor Green
                # Store the original relative path for git add
                $ModifiedFiles += $File
            }
            else {
                Write-Host "  → No changes needed" -ForegroundColor Gray
            }
        }
        else {
            Write-Warning "Linter failed for $File`: $Result"
        }
    }
    catch {
        Write-Warning "Error processing $File`: $($_.Exception.Message)"
    }

    $FilesProcessed++
}

# Re-stage modified files if any
if ($ModifiedFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "Re-staging $($ModifiedFiles.Count) modified file(s)..." -ForegroundColor Cyan

    # Change back to repository root
    Set-Location $RepoRoot

    foreach ($ModifiedFile in $ModifiedFiles) {
        try {
            Write-Host "  Staging: $ModifiedFile" -ForegroundColor Green
            & git add $ModifiedFile

            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Failed to stage $ModifiedFile"
            }
        }
        catch {
            Write-Warning "Error staging $ModifiedFile`: $($_.Exception.Message)"
        }
    }

    Write-Host ""
    Write-Host "✅ Modified files have been re-staged for commit." -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Host "✅ No files needed modification." -ForegroundColor Green
}

Write-Host "Processed $FilesProcessed file(s), modified $($ModifiedFiles.Count)" -ForegroundColor Cyan

# Always return success so commit proceeds
exit 0
