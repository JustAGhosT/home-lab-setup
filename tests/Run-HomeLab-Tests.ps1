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
    $reportPath = Join-Path $PSScriptRoot "TestReport.html"
    
    try {
        # Try PScribo first
        if (-not (Get-Module -Name PScribo -ListAvailable)) {
            Write-Host "Installing PScribo module for report generation..."
            Install-Module -Name PScribo -Force -SkipPublisherCheck -ErrorAction Stop
        }
        
        Import-Module -Name PScribo
        
        Document "HomeLab Test Report" {
            Section "Test Summary" {
                Paragraph "Test Run Date: $(Get-Date)"
                Paragraph "Test Type: $TestType"
                
                Paragraph "Total Tests: $($testResults.TotalCount)"
                Paragraph "Passed: $($testResults.PassedCount)"
                Paragraph "Failed: $($testResults.FailedCount)"
                Paragraph "Skipped: $($testResults.SkippedCount)"
                $passRate = if ($testResults.TotalCount -gt 0) { [math]::Round(($testResults.PassedCount / $testResults.TotalCount) * 100, 2) } else { 0 }
                Paragraph "Pass Rate: $passRate%"
            }
            
            if ($Coverage) {
                Section "Code Coverage" {
                    Paragraph "Code coverage analysis results:"
                    
                    $filesAnalyzed = if ($testResults.CodeCoverage) { $testResults.CodeCoverage.NumberOfCommandsAnalyzed } else { 0 }
                    $commandsCovered = if ($testResults.CodeCoverage) { $testResults.CodeCoverage.NumberOfCommandsExecuted } else { 0 }
                    $coveragePercent = if ($testResults.CodeCoverage -and $testResults.CodeCoverage.NumberOfCommandsAnalyzed -gt 0) { 
                        [math]::Round(($testResults.CodeCoverage.NumberOfCommandsExecuted / $testResults.CodeCoverage.NumberOfCommandsAnalyzed) * 100, 2) 
                    } else { 0 }
                    Paragraph "Files Analyzed: $filesAnalyzed"
                    Paragraph "Commands Covered: $commandsCovered"
                    Paragraph "Coverage Percentage: $coveragePercent%"
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
        } | Export-Document -Path $PSScriptRoot -Format HTML -Options @{ 'FileName' = 'TestReport' }
        
        Write-Host "Report generated at: $reportPath" -ForegroundColor Green
    }
    catch {
        Write-Host "PScribo failed, generating simple HTML report..." -ForegroundColor Yellow
        
        $passRate = if ($testResults.TotalCount -gt 0) { [math]::Round(($testResults.PassedCount / $testResults.TotalCount) * 100, 2) } else { 0 }
        
        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>HomeLab Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 10px; border-radius: 5px; }
        .summary { margin: 20px 0; }
        .passed { color: green; }
        .failed { color: red; }
        .skipped { color: orange; }
    </style>
</head>
<body>
    <div class="header">
        <h1>HomeLab Test Report</h1>
        <p>Test Run Date: $(Get-Date)</p>
        <p>Test Type: $TestType</p>
    </div>
    
    <div class="summary">
        <h2>Test Summary</h2>
        <p>Total Tests: $($testResults.TotalCount)</p>
        <p class="passed">Passed: $($testResults.PassedCount)</p>
        <p class="failed">Failed: $($testResults.FailedCount)</p>
        <p class="skipped">Skipped: $($testResults.SkippedCount)</p>
        <p>Pass Rate: $passRate%</p>
    </div>
</body>
</html>
"@
        
        $htmlContent | Out-File -FilePath $reportPath -Encoding UTF8
        Write-Host "Fallback report generated at: $reportPath" -ForegroundColor Green
    }
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