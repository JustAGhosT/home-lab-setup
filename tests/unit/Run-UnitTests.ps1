# Run-UnitTests.ps1
# Script to run all unit tests for the HomeLab modules

# Check if Pester module is installed
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Pester module not found. Installing Pester..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Import Pester module
Import-Module Pester

# Define test paths
$unitTestsRoot = $PSScriptRoot

# Validate unit tests directory structure
if (-not (Test-Path $unitTestsRoot)) {
    Write-Error "Unit tests directory not found at: $unitTestsRoot"
    Write-Error "Please ensure the script is run from the correct location."
    exit 1
}

# Verify mock files exist
$mockFiles = @(
    Join-Path $unitTestsRoot "HomeLab.Azure.Mock.ps1",
    Join-Path $unitTestsRoot "HomeLab.Core.Mock.ps1",
    Join-Path $unitTestsRoot "HomeLab.Security.Mock.ps1"
)

$allMocksExist = $true
foreach ($mockFile in $mockFiles) {
    if (-not (Test-Path $mockFile)) {
        Write-Warning "Mock file not found: $mockFile"
        $allMocksExist = $false
    }
}

if (-not $allMocksExist) {
    Write-Error "One or more mock files are missing. Please ensure all mock files exist before running tests."
    exit 1
}

# Configure Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $unitTestsRoot
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path $unitTestsRoot "TestResults.xml"

# Run the tests
Write-Host "Executing unit tests..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Validate test execution results
if (-not $testResults) {
    Write-Error "No results returned from Pester test execution."
    Write-Error "This may indicate a serious issue with test execution or configuration."
    Write-Error "Please check:"
    Write-Error "  - Test files exist and are properly formatted"
    Write-Error "  - Mock files are properly loaded"
    Write-Error "  - No syntax errors in test files"
    exit 1
}

if ($testResults.TotalCount -eq 0) {
    Write-Warning "No tests were discovered or executed."
    Write-Warning "Please verify that test files exist in: $unitTestsRoot"
    Write-Warning "Test files should have names ending with '.tests.ps1'"
}

Write-Host "Tests completed. Check the results above."
Write-Host "Test results saved to: $(Join-Path $unitTestsRoot 'TestResults.xml')"

# Output summary
Write-Host ""
Write-Host "Test Summary:"
Write-Host "------------"
Write-Host "Total Tests: $($testResults.TotalCount)"
Write-Host "Passed: $($testResults.PassedCount)"
Write-Host "Failed: $($testResults.FailedCount)"
Write-Host "Skipped: $($testResults.SkippedCount)"

# Return exit code based on test results
if ($testResults.FailedCount -gt 0) {
    exit 1
}
else {
    exit 0
}