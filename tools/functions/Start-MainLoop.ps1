<#
.SYNOPSIS
    Main application loop for HomeLab management console with diagnostic wrapper
.DESCRIPTION
    Handles the main menu loop and user interaction flow for the HomeLab management console
.PARAMETER DebugMode
    If specified, enables additional debug output.
.EXAMPLE
    Start-MainLoop -DebugMode
.NOTES
    Author: Jurie Smit
    Date: March 12, 2025
#>
function Start-MainLoop {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$DebugMode
    )
    
    do {
        $shouldRestart = $false
        try {
        # Add a diagnostic wrapper
        if ($DebugMode) {
            Write-Host "=== DIAGNOSTIC MODE ENABLED ===" -ForegroundColor Magenta
            Write-Host "Entering Start-MainLoop with DebugMode=$DebugMode" -ForegroundColor Magenta
            
            # Check if we're in a nested call
            $callStack = Get-PSCallStack
            if ($callStack.Count -gt 2) {
                Write-Host "WARNING: Detected nested call to Start-MainLoop. Call stack:" -ForegroundColor Yellow
                $callStack | Format-Table -AutoSize
            }
        }
        
        # Initialize application state if not already initialized
        if (-not $script:State) {
            $script:State = @{
                StartTime = Get-Date
                User = $env:USERNAME
                ConnectionStatus = "Disconnected"
                ConfigPath = $null
                # Add a flag to prevent recursive exit
                PreventExit = $true
            }
        }
        
        # Call the main menu handler function
        if ($DebugMode) {
            Write-Host "DEBUG: About to call Invoke-MainMenu with Debug mode" -ForegroundColor Magenta
            $result = Invoke-MainMenu -State $script:State -ShowProgress -DebugMode
            Write-Host "DEBUG: Invoke-MainMenu returned: $result" -ForegroundColor Magenta
        }
        else {
            $result = Invoke-MainMenu -State $script:State -ShowProgress
        }
        
        Write-Log -Message "Main menu loop ended with result: $result" -Level "Info"
        return $result
    }
    catch {
        $errorMessage = $_.Exception.Message
        $errorLine = $_.InvocationInfo.ScriptLineNumber
        $errorScript = $_.InvocationInfo.ScriptName
        $errorPosition = $_.InvocationInfo.PositionMessage
        
        Write-Log -Message "Critical error in Start-MainLoop: $errorMessage" -Level "Error"
        Write-Log -Message "Script: $errorScript, Line: $errorLine" -Level "Error"
        Write-Log -Message "Position: $errorPosition" -Level "Error"
        Write-Log -Message "Stack Trace: $($_.ScriptStackTrace)" -Level "Error"
        
        # Display error to user
        Write-Host "`nA critical error occurred in the application:" -ForegroundColor Red
        Write-Host $errorMessage -ForegroundColor Red
        Write-Host "Please check the log file for details." -ForegroundColor Yellow
        
        # Ask user if they want to restart the application
        Write-Host "`nWould you like to restart the application? (Y/N)" -ForegroundColor Yellow
        $restart = Read-Host
        $shouldRestart = ($restart -eq "Y" -or $restart -eq "y")
        if (-not $shouldRestart) {
            return $false
        }
    } while ($shouldRestart)
}


# Export the function
Export-ModuleMember -Function Start-MainLoop
