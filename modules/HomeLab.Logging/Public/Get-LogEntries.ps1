function Get-LogEntries {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = $Global:Config.LogFile,
        
        [Parameter(Mandatory = $false)]
        [string]$Pattern,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level,
        
        [Parameter(Mandatory = $false)]
        [datetime]$StartTime,
        
        [Parameter(Mandatory = $false)]
        [datetime]$EndTime,
        
        [Parameter(Mandatory = $false)]
        [int]$Tail
    )
    
    # Check if the log file exists
    if (-not (Test-Path -Path $LogFilePath)) {
        Write-Host "Log file does not exist at $LogFilePath" -ForegroundColor Yellow
        return @()
    }
    
    # Read the log file
    $logContent = Get-Content -Path $LogFilePath
    
    # Parse log entries
    $logEntries = @()
    foreach ($line in $logContent) {
        # Skip header lines and empty lines
        if ($line -match '^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\] \[(\w+)\] (.+)$') {
            $timestamp = [datetime]::ParseExact($matches[1], 'yyyy-MM-dd HH:mm:ss', $null)
            $entryLevel = $matches[2]
            $message = $matches[3]
            
            $logEntries += [PSCustomObject]@{
                Timestamp = $timestamp
                Level = $entryLevel
                Message = $message
                OriginalLine = $line
            }
        }
    }
    
    # Apply filters
    if ($Pattern) {
        $logEntries = $logEntries | Where-Object { $_.Message -match $Pattern -or $_.OriginalLine -match $Pattern }
    }
    
    if ($Level) {
        $logEntries = $logEntries | Where-Object { $_.Level -eq $Level }
    }
    
    if ($StartTime) {
        $logEntries = $logEntries | Where-Object { $_.Timestamp -ge $StartTime }
    }
    
    if ($EndTime) {
        $logEntries = $logEntries | Where-Object { $_.Timestamp -le $EndTime }
    }
    
    # Apply tail if specified
    if ($Tail -gt 0) {
        $logEntries = $logEntries | Select-Object -Last $Tail
    }
    
    return $logEntries
}
