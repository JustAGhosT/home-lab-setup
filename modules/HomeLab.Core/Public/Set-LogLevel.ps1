function Set-LogLevel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$ConsoleLevel = 'Info',
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$FileLevel = 'Info'
    )
    
    # Define log level priorities
    $logLevelPriority = @{
        'Info'    = 0
        'Success' = 1
        'Warning' = 2
        'Error'   = 3
    }
    
    # Store the log levels in the global configuration
    $Global:Config.LogLevels = @{
        Console = $ConsoleLevel
        File    = $FileLevel
        ConsolePriority = $logLevelPriority[$ConsoleLevel]
        FilePriority    = $logLevelPriority[$FileLevel]
    }
    
    Write-Log -Message "Log levels set - Console: $ConsoleLevel, File: $FileLevel" -Level Info -Force
}
