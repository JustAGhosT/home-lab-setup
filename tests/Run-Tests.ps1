param(
    [ValidateSet('Unit', 'Integration', 'Workflow', 'All')]
    [string]$TestType = 'Unit',
    
    [switch]$Coverage,
    
    [switch]$CI
)

# Check and install PowerShell-Yaml module if needed
if (-not (Get-Module -ListAvailable -Name PowerShell-Yaml)) {
    Write-Host "Installing PowerShell-Yaml module..." -ForegroundColor Yellow
    Install-Module -Name PowerShell-Yaml -Force -Scope CurrentUser
}
Import-Module PowerShell-Yaml

# Check if Pester 5.0+ is available
$pesterModule = Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version.Major -ge 5 }

if (-not $pesterModule) {
    Write-Host "Pester 5.0 or higher is required. Running Update-Pester.ps1..." -ForegroundColor Yellow
    
    # Run the Update-Pester script if it exists
    $updateScript = Join-Path $PSScriptRoot "Update-Pester.ps1"
    if (Test-Path $updateScript) {
        & $updateScript
    } else {
        Write-Error "Pester 5.0+ is required but not installed. Please run Update-Pester.ps1 first."
        exit 1
    }
}

# Import Pester 5.0+
Import-Module Pester -MinimumVersion 5.0

# Configure test run
$config = New-PesterConfiguration

# Set test path based on type
Write-Host "Running $TestType tests..."
switch ($TestType) {
    'Unit' { $config.Run.Path = ".\unit" }
    'Integration' { $config.Run.Path = ".\integration" }
    'Workflow' { $config.Run.Path = ".\workflow" }
    'All' { $config.Run.Path = "." }
}

# Configure output
$config.Output.Verbosity = 'Detailed'

# Configure test results for CI
if ($CI) {
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputFormat = 'NUnitXml'
    $config.TestResult.OutputPath = ".\TestResults.xml"
}

# Configure code coverage if requested
if ($Coverage) {
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = @(
        "$PSScriptRoot\..\HomeLab\modules\*\Public\*.ps1"
        "$PSScriptRoot\..\HomeLab\modules\*\Private\*.ps1"
        "$PSScriptRoot\..\functions\*.ps1"
        "$PSScriptRoot\..\HomeLab\functions\*.ps1"
    )
    $config.CodeCoverage.OutputPath = ".\coverage.xml"
    $config.CodeCoverage.OutputFormat = 'JaCoCo'
    
    Write-Host "Code coverage enabled. Results will be saved to coverage.xml"
}

# Run tests
$testResults = Invoke-Pester -Configuration $config

# Output summary
Write-Host "`nTest Summary:"
Write-Host "  Total: $($testResults.TotalCount)"
Write-Host "  Passed: $($testResults.PassedCount)"
Write-Host "  Failed: $($testResults.FailedCount)"
Write-Host "  Skipped: $($testResults.SkippedCount)"

# Return exit code for CI systems
if ($testResults.FailedCount -gt 0) {
    Write-Host "Tests failed. See detailed output above."
    if ($CI) { exit 1 }
} else {
    Write-Host "All tests passed!"
    if ($CI) { exit 0 }
}