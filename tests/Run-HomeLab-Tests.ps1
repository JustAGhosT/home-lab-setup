[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Unit', 'Integration', 'Workflow', 'All')]
    [string]$TestType = 'All',
    
    [Parameter()]
    [switch]$Coverage,
    
    [Parameter()]
    [switch]$GenerateReport
)

# Import required modules
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installing Pester module..."
    try {
        Install-Module -Name Pester -MinimumVersion 5.0 -Force -SkipPublisherCheck
        Write-Host "Pester module installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install Pester module: $_" -ForegroundColor Red
        exit 1
    }
}

Import-Module -Name Pester -MinimumVersion 5.0

# Configure test run
$config = New-PesterConfiguration
$config.Run.Path = $PSScriptRoot
$config.Run.PassThru = $true  # Enable result object return
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = Join-Path $PSScriptRoot "TestResults.xml"
$config.Output.Verbosity = "Detailed"

# Set test path based on type
switch ($TestType) {
    'Unit' { 
        $config.Run.Path = Join-Path $PSScriptRoot "unit"
        Write-Host "Running Unit Tests..." -ForegroundColor Cyan
    }
    'Integration' { 
        $config.Run.Path = Join-Path $PSScriptRoot "integration"
        Write-Host "Running Integration Tests..." -ForegroundColor Cyan
    }
    'Workflow' { 
        $config.Run.Path = Join-Path $PSScriptRoot "workflow"
        Write-Host "Running Workflow Tests..." -ForegroundColor Cyan
    }
    'All' { 
        $config.Run.Path = $PSScriptRoot
        Write-Host "Running All Tests..." -ForegroundColor Cyan
    }
}

# Configure code coverage if requested
if ($Coverage) {
    Write-Host "Enabling code coverage..." -ForegroundColor Cyan
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = @(
        Join-Path $PSScriptRoot "..\HomeLab\modules\HomeLab.Core\*.ps1"
        Join-Path $PSScriptRoot "..\HomeLab\modules\HomeLab.Azure\*.ps1"
        Join-Path $PSScriptRoot "..\HomeLab\modules\HomeLab.Security\*.ps1"
        Join-Path $PSScriptRoot "..\HomeLab\modules\HomeLab.Web\*.ps1"
        Join-Path $PSScriptRoot "..\HomeLab\modules\HomeLab.DNS\*.ps1"
    )
    $config.CodeCoverage.OutputPath = Join-Path $PSScriptRoot "coverage.xml"
}

# Run tests
$testResults = Invoke-Pester -Configuration $config

# Generate HTML report if requested
if ($GenerateReport) {
    
    # Check if we have the module for report generation
    if (-not (Get-Module -Name PScribo -ListAvailable)) {
        Write-Host "Installing PScribo module for report generation..."
        try {
            Install-Module -Name PScribo -Force -SkipPublisherCheck -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to install PScribo module: $_"
            Write-Host "HTML report generation will be skipped" -ForegroundColor Yellow
            return
        }
    }
    
    Import-Module -Name PScribo
    
    # Generate report
    $reportPath = Join-Path $PSScriptRoot "TestReport.html"
    
    Document "HomeLab Test Report" {
        Section "Test Summary" {
            Paragraph "Test Run Date: $(Get-Date)"
            Paragraph "Test Type: $TestType"
            
            Table -Name "Test Results Summary" -Hashtable @{
                "Total Tests" = $testResults.TotalCount
                "Passed"      = $testResults.PassedCount
                "Failed"      = $testResults.FailedCount
                "Skipped"     = $testResults.SkippedCount
                "Pass Rate"   = if ($testResults.TotalCount -gt 0) { [math]::Round(($testResults.PassedCount / $testResults.TotalCount) * 100, 2) } else { 0 }
            }
        }
        
        if ($Coverage) {
            Section "Code Coverage" {
                Paragraph "Code coverage analysis results:"
                
                Table -Name "Coverage Summary" -Hashtable @{
                    "Files Analyzed"   = if ($testResults.CodeCoverage) { $testResults.CodeCoverage.NumberOfCommandsAnalyzed } else { 0 }
                    "Commands Covered" = if ($testResults.CodeCoverage) { $testResults.CodeCoverage.NumberOfCommandsExecuted } else { 0 }
                    "Coverage %"       = if ($testResults.CodeCoverage -and $testResults.CodeCoverage.NumberOfCommandsAnalyzed -gt 0) { 
                        [math]::Round(($testResults.CodeCoverage.NumberOfCommandsExecuted / $testResults.CodeCoverage.NumberOfCommandsAnalyzed) * 100, 2) 
                    }
                    else { 0 }
                }
            }
        }
        
        Section "Test Details" {
            foreach ($result in $testResults.Tests) {
                Section $result.Name {
                    Paragraph "Result: $($result.Result)"
                    if ($result.Result -eq "Failed") {
                        Paragraph "Error: $($result.ErrorRecord)"
                    }
                }
            }
        }
    } | Export-Document -Path $reportPath -Format HTML
    
    Write-Host "Report generated at: $reportPath" -ForegroundColor Green
}

# Return results summary
Write-Host "Test Results Summary:" -ForegroundColor Cyan
Write-Host "  Total Tests: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  Passed: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Failed: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "  Skipped: $($testResults.SkippedCount)" -ForegroundColor Yellow

if ($testResults.FailedCount -gt 0) {
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    $testResults.Failed | ForEach-Object {
        Write-Host "  - $($_.Name): $($_.ErrorRecord)" -ForegroundColor Red
    }
    exit 1
}
else {
    Write-Host "`nAll tests passed!" -ForegroundColor Green
    exit 0
}