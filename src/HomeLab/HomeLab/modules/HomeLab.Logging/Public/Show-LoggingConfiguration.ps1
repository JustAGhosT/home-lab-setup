function Show-LoggingConfiguration {
    [CmdletBinding()]
    param()
    
    Write-ColorOutput "=== LOGGING CONFIGURATION ===" -ForegroundColor Cyan
    Write-ColorOutput "Log File Path: $($Global:Config.LogFile)" -ForegroundColor Cyan
    
    $consoleLogLevel = if ($Global:Config.Logging.ConsoleLogLevel) { 
        $Global:Config.Logging.ConsoleLogLevel 
    } else { 
        $Global:Config.Logging.DefaultLogLevel 
    }
    
    $fileLogLevel = if ($Global:Config.Logging.FileLogLevel) { 
        $Global:Config.Logging.FileLogLevel 
    } else { 
        $Global:Config.Logging.DefaultLogLevel 
    }
    
    Write-ColorOutput "Console Logging: $($Global:Config.Logging.EnableConsoleLogging)" -ForegroundColor Cyan
    Write-ColorOutput "File Logging: $($Global:Config.Logging.EnableFileLogging)" -ForegroundColor Cyan
    Write-ColorOutput "Console Log Level: $consoleLogLevel" -ForegroundColor Cyan
    Write-ColorOutput "File Log Level: $fileLogLevel" -ForegroundColor Cyan
    Write-ColorOutput "Default Log Level: $($Global:Config.Logging.DefaultLogLevel)" -ForegroundColor Cyan
    Write-ColorOutput "Max Log Age (Days): $($Global:Config.Logging.MaxLogAgeDays)" -ForegroundColor Cyan
    
    # Test log file accessibility
    $logFileAccessible = $false
    $logDir = Split-Path -Parent $Global:Config.LogFile
    if (Test-Path $logDir -PathType Container) {
        try {
            $testFile = Join-Path $logDir "test_write_access.tmp"
            "Test" | Out-File -FilePath $testFile -ErrorAction Stop
            Remove-Item $testFile -ErrorAction SilentlyContinue
            $logFileAccessible = $true
        }
        catch {}
    }
    
    Write-ColorOutput "Log Directory Accessible: $logFileAccessible" -ForegroundColor $(if ($logFileAccessible) { "Green" } else { "Red" })
    Write-ColorOutput "==============================" -ForegroundColor Cyan
}
