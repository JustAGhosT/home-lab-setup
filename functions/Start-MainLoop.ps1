<#
.SYNOPSIS
    Main application loop for HomeLab management console
.DESCRIPTION
    Handles the main menu loop and user interaction flow for the HomeLab management console
.NOTES
    Author: Jurie Smit
    Version: 1.0.0
    Date: March 10, 2025
#>

function Start-MainLoop {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$DebugMode
    )
    
    try {
        # Check if HomeLab.UI module is available
        if (-not (Get-Module -Name HomeLab.UI -ErrorAction SilentlyContinue)) {
            Write-Log -Message "HomeLab.UI module not loaded. Attempting to load it." -Level "Warning"
            
            # Try to import the module
            try {
                $uiModulePath = Join-Path -Path "$PSScriptRoot\..\modules" -ChildPath "HomeLab.UI\HomeLab.UI.psm1"
                Import-Module -Name $uiModulePath -ErrorAction Stop
                Write-Log -Message "HomeLab.UI module loaded successfully." -Level "Info"
            }
            catch {
                Write-Log -Message "Failed to load HomeLab.UI module: $_" -Level "Error"
                Write-Host "ERROR: HomeLab.UI module could not be loaded. The application cannot continue." -ForegroundColor Red
                return $false
            }
        }
        
        # Validate required functions exist
        $requiredFunctions = @("Show-Menu", "Show-MainMenu", "Invoke-MainMenu")
        $missingFunctions = @()
        
        foreach ($function in $requiredFunctions) {
            if (-not (Get-Command -Name $function -ErrorAction SilentlyContinue)) {
                $missingFunctions += $function
            }
        }
        
        if ($missingFunctions.Count -gt 0) {
            $missingFunctionsList = $missingFunctions -join ", "
            Write-Log -Message "Required function(s) not found: $missingFunctionsList" -Level "Error"
            Write-Host "ERROR: Required function(s) not found: $missingFunctionsList" -ForegroundColor Red
            return $false
        }
        
        # Initialize application state if not already initialized
        if (-not $script:State) {
            $script:State = @{
                StartTime = Get-Date
                User = $env:USERNAME
                ConnectionStatus = "Disconnected"
                ConfigPath = $null
            }
        }
        
        # Start the main menu loop
        Write-Log -Message "Starting main menu loop" -Level "Info"
        
        # Call the main menu handler function
        if ($DebugMode) {
            Write-Host "DEBUG: About to call Invoke-MainMenu with Debug mode" -ForegroundColor Magenta
            $result = Invoke-MainMenu -State $script:State -ShowProgress -Debug
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
        if ($restart -eq "Y" -or $restart -eq "y") {
            Start-MainLoop -DebugMode:$DebugMode  # Recursive call to restart
        }
        
        return $false
    }
}

# Export the function
Export-ModuleMember -Function Start-MainLoop
