# Run-UnitTests.ps1
# Script to run all unit tests for the HomeLab modules

# Check if Pester module is installed
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Pester module not found. Installing Pester..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Import Pester module
Import-Module Pester

# Verify mock files exist
$mockFiles = @(
    "$PSScriptRoot\HomeLab.Azure.Mock.ps1",
    "$PSScriptRoot\HomeLab.Core.Mock.ps1",
    "$PSScriptRoot\HomeLab.Security.Mock.ps1"
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
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = "$PSScriptRoot\TestResults.xml"

# Run the tests
$testResults = Invoke-Pester -Configuration $pesterConfig

Write-Host "Tests completed. Check the results above."
Write-Host "Test results saved to: $PSScriptRoot\TestResults.xml"

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
} else {
    exit 0
}