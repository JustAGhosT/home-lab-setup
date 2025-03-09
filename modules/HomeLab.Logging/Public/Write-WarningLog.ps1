<#
.SYNOPSIS
    Writes a warning log message
.DESCRIPTION
    Wrapper function for Write-Log that specifically logs messages with the Warning level
.PARAMETER Message
    The message to log
.PARAMETER LogFilePath
    Optional path to the log file. If not specified, uses the current log file path
.EXAMPLE
    Write-WarningLog -Message "Configuration file not found, using defaults"
.NOTES
    Part of HomeLab.Logging module
#>
function Write-WarningLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = $script:LogPath
    )
    
    Write-Log -Message $Message -Level Warning -LogFile $LogFilePath
}
