<#
.SYNOPSIS
    Writes an informational log message
.DESCRIPTION
    Wrapper function for Write-Log that specifically logs messages with the Info level
.PARAMETER Message
    The message to log
.PARAMETER LogFilePath
    Optional path to the log file. If not specified, uses the current log file path
.EXAMPLE
    Write-InfoLog -Message "Configuration loaded successfully"
.NOTES
    Part of HomeLab.Logging module
#>
function Write-InfoLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = $script:LogPath
    )
    
    Write-Log -Message $Message -Level Info -LogFile $LogFilePath
}
