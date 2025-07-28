#Requires -Version 7.0
<#
.SYNOPSIS
    Runs all tests for the HomeLab project.
.DESCRIPTION
    This script runs unit tests and integration tests for the HomeLab project.
    It can be configured to run specific test types or tests for specific modules.
.PARAMETER UnitOnly
    Run only unit tests.
.PARAMETER IntegrationOnly
    Run only integration tests.
.PARAMETER Module
    Run tests only for the specified module(s).
.PARAMETER OutputPath
    Path where test results will be saved.
.EXAMPLE
    .\Test-HomeLab.ps1
    Runs all tests.
.EXAMPLE
    .\Test-HomeLab.ps1 -UnitOnly
    Runs only unit tests.
.EXAMPLE
    .\Test-HomeLab.ps1 -Module Core,Azure
    Runs tests only for HomeLab.Core and HomeLab.Azure modules.
#>
[CmdletBinding()]
param (
    [Parameter()]
    [switch]$UnitOnly,
    
    [Parameter()]
    [switch]$IntegrationOnly,
    
    [Parameter()]
    [string[]]$Module,
    
    [Parameter()]
    [string]$OutputPath = "$PSScriptRoot\TestResults"
)

# Ensure Pester is installed
try {
    $pesterModule = Get-Module -ListAvailable -Name Pester
    if (-not $pesterModule) {
        Write-Host "Installing Pester module..." -ForegroundColor Yellow
        Install-Module -Name Pester -Force -SkipPublisherCheck -ErrorAction Stop
    }
    elseif ($pesterModule.Version -lt [Version]"5.0.0") {
        Write-Warning "Pester version $($pesterModule.Version) detected. Version 5.0+ recommended."
    }
}
catch {
    Write-Error "Failed to install Pester module: $_"
    exit 1
}

# Import Pester
try {
    Import-Module Pester -ErrorAction Stop
}
catch {
    Write-Error "Failed to import Pester module: $_"
    exit 1
}

# Create output directory if it doesn't exist
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Define test paths
$unitTestPath = "$PSScriptRoot\tests\unit"
$integrationTestPath = "$PSScriptRoot\tests\integration"

# Configure Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'

# Determine which tests to run
$testPaths = @()

if (-not $IntegrationOnly) {
    if (Test-Path $unitTestPath) {
        $testPaths += $unitTestPath
    }
}

# Filter by module if specified
if ($Module) {
    $filteredPaths = @()
    foreach ($testPath in $testPaths) {
        foreach ($mod in $Module) {
            $modPath = Join-Path $testPath "HomeLab.$mod.tests.ps1"
            if (Test-Path $modPath) {
                $filteredPaths += $modPath
            }
            else {
                Write-Warning "Test file not found for module '$mod': $modPath"
            }
        }
    }
    if ($filteredPaths.Count -gt 0) {
        $testPaths = $filteredPaths
    }
    else {
        Write-Error "No test files found for specified modules: $($Module -join ', ')"
        exit 1
    }
}

# Set test paths in Pester configuration
$pesterConfig.Run.Path = $testPaths

# Run tests for each path
$totalTests = 0
$totalPassed = 0
$totalFailed = 0
$allResults = @()

Write-Host "Running HomeLab tests..." -ForegroundColor Cyan
Write-Host "Test paths: $($testPaths -join ', ')" -ForegroundColor Cyan

foreach ($path in $testPaths) {
    $pathName = Split-Path -Leaf $path
    $resultPath = Join-Path -Path $OutputPath -ChildPath "$pathName-results.xml"
    $pesterConfig.TestResult.OutputPath = $resultPath
    
    Write-Host "Running tests in $path..." -ForegroundColor Yellow
    try {
        $results = Invoke-Pester -Configuration $pesterConfig
        
        if (-not $results) {
            Write-Error "No results returned from Pester for path: $path"
            continue
        }
    } catch {
        Write-Error "Failed to run tests for path '$path': $_"
        $totalFailed += 1
        continue
    }
    
    $totalTests += $results.TotalCount
    $totalPassed += $results.PassedCount
    $totalFailed += $results.FailedCount
    $allResults += $results
}

# Display summary
Write-Host "`nTest Summary:" -ForegroundColor Cyan
Write-Host "=============" -ForegroundColor Cyan
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $totalPassed" -ForegroundColor Green
Write-Host "Failed: $totalFailed" -ForegroundColor Red
Write-Host "Test results saved to: $OutputPath" -ForegroundColor White

# Return exit code based on test results
if ($totalFailed -gt 0) {
    exit 1
} else {
    exit 0
}