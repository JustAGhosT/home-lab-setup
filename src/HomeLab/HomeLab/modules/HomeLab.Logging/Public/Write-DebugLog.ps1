<#
.SYNOPSIS
    Writes a debug log message
.DESCRIPTION
    Wrapper function for Write-Log that logs debug messages as Info level
    Only writes logs if DebugPreference is not SilentlyContinue
.PARAMETER Message
    The message to log
.PARAMETER LogFilePath
    Optional path to the log file. If not specified, uses the current log file path
.EXAMPLE
    Write-DebugLog -Message "Variable value: $variableValue"
.NOTES
    Part of HomeLab.Logging module
#>
function Write-DebugLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = $script:LogPath
    )
    
    # Only write debug logs if debug preference is set appropriately
    if ($DebugPreference -ne 'SilentlyContinue') {
        Write-Log -Message "DEBUG: $Message" -Level Info -LogFile $LogFilePath
    }
}
