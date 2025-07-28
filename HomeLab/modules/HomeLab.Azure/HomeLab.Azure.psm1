<#
.SYNOPSIS
    HomeLab Azure Module
.DESCRIPTION
    Module for HomeLab Azure infrastructure deployment.
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
    Version: 1.0.0
#>

$ModulePath = $PSScriptRoot
$ModuleName = (Get-Item $PSScriptRoot).BaseName

# Load dependencies
$requiredModules = @('HomeLab.Utils', 'HomeLab.Logging', 'HomeLab.Core')
foreach ($module in $requiredModules) {
    if (-not (Get-Module -Name $module)) {
        $parentPath = Split-Path -Parent $ModulePath
        $siblingPath = Join-Path $parentPath $module
        $manifestPath = Join-Path $siblingPath "$module.psd1"
        if (Test-Path $manifestPath) {
            Import-Module $manifestPath -Force -ErrorAction SilentlyContinue
        }
        else {
            Import-Module $module -Force -ErrorAction SilentlyContinue
        }
    }
}

# Load private functions with error handling
$privatePath = Join-Path $ModulePath 'Private'
$privateCount = 0
if (Test-Path $privatePath) {
    Write-Host "Loading private functions from $privatePath..." -ForegroundColor Cyan
    Write-Verbose "Found private functions directory: $privatePath"

    $privateFiles = Get-ChildItem "$privatePath\*.ps1" -Recurse -ErrorAction SilentlyContinue
    Write-Verbose "Found $($privateFiles.Count) private function files"

    foreach ($file in $privateFiles) {
        try {
            Write-Verbose "Loading private function: $($file.Name)"
            . $file.FullName
            $privateCount++
            Write-Verbose "Successfully loaded private function from: $($file.Name)"
        }
        catch {
            Write-Warning "Failed to load private function from '$($file.Name)': $($_.Exception.Message)"
            Write-Verbose "Error details: $($_.Exception.ToString())"
            # Continue loading other functions instead of failing completely
        }
    }

    Write-Host "  SUCCESS: Loaded $privateCount private functions" -ForegroundColor Green
}
else {
    Write-Warning "Private directory not found: $privatePath"
}

# Load and export public functions
$publicPath = Join-Path $ModulePath 'Public'
$publicFunctions = @()
$publicCount = 0

if (Test-Path $publicPath) {
    Write-Host "Loading public functions from $publicPath..." -ForegroundColor Cyan
    Write-Verbose "Found public functions directory: $publicPath"

    $publicFiles = Get-ChildItem "$publicPath\*.ps1" -Recurse -ErrorAction SilentlyContinue
    Write-Verbose "Found $($publicFiles.Count) public function files"

    foreach ($file in $publicFiles) {
        try {
            Write-Verbose "Loading public function: $($file.Name)"
            . $file.FullName

            # Extract function name from file with improved robustness
            $content = Get-Content $file.FullName -Raw
            # Extract all function definitions (excluding commented lines)
            $functionMatches = [regex]::Matches($content, '^\s*function\s+([\w-]+)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline)
            foreach ($match in $functionMatches) {
                $functionName = $match.Groups[1].Value
                # Verify the function actually exists in current scope and is not a reserved word
                if ($functionName -and $functionName -ne 'returns' -and (Get-Command $functionName -ErrorAction SilentlyContinue)) {
                    $publicFunctions += $functionName
                    Write-Verbose "Exported public function: $functionName"
                }
            }
            $publicCount++
            Write-Verbose "Successfully loaded public function from: $($file.Name)"
        }
        catch {
            Write-Warning "Failed to load public function from '$($file.Name)': $($_.Exception.Message)"
            Write-Verbose "Error details: $($_.Exception.ToString())"
            # Continue loading other functions instead of failing completely
        }
    }

    Write-Host "  SUCCESS: Loaded $publicCount public functions" -ForegroundColor Green
}
else {
    Write-Warning "Public directory not found: $publicPath"
}

# Export public functions
if ($publicFunctions.Count -gt 0) {
    $uniqueFunctions = $publicFunctions | Select-Object -Unique
    Export-ModuleMember -Function $uniqueFunctions
    Write-Host "HomeLab.Azure module loaded successfully" -ForegroundColor Green
    Write-Verbose "Exported $($uniqueFunctions.Count) unique public functions: $($uniqueFunctions -join ', ')"
}
else {
    Write-Warning "No public functions found to export"
}