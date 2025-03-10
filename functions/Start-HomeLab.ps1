<#
.SYNOPSIS
    Starts the HomeLab management console
.DESCRIPTION
    Entry point for the HomeLab management console. Initializes the environment,
    shows the splash screen, and starts the main application loop.
.NOTES
    Author: Jurie Smit
    Version: 1.0.0
    Date: March 10, 2025
#>

function Start-HomeLab {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = "$env:USERPROFILE\.homelab\config.json",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Debug", "Info", "Warning", "Error", "Success")]
        [string]$LogLevel = "Info",
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipSplashScreen,
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipModuleCheck,
        
        [Parameter(Mandatory = $false)]
        [switch]$DebugMode
    )
    
    try {        
        
        # Initialize script variables if not already set
        if (-not $script:StartTime) {
            $script:StartTime = Get-Date
        }
        
        if (-not $script:Version) {
            $script:Version = '1.0.0'
        }

        # Create default log file path
        $logFileName = "homelab_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        $logDir = Join-Path -Path $env:USERPROFILE -ChildPath ".homelab\logs"
        $logFilePath = Join-Path -Path $logDir -ChildPath $logFileName
        
        # Ensure log directory exists
        if (-not (Test-Path -Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        
        # Initialize environment with explicit log file path
        $initialized = Initialize-Environment -ConfigPath $ConfigPath -LogLevel $LogLevel -LogFilePath $logFilePath -SkipModuleCheck:$SkipModuleCheck
        if (-not $initialized) {
            Write-Host "Failed to initialize HomeLab environment. Exiting." -ForegroundColor Red
            return $false
        }
        
        # Show splash screen unless skipped
        if (-not $SkipSplashScreen) {
            # Brief pause to allow user to see any startup messages
            Wait-BeforeSplash -Seconds 3
            
            # Show splash screen if the function exists
            if (Get-Command -Name Show-SplashScreen -ErrorAction SilentlyContinue) {
                Show-SplashScreen
            }
            else {
                Write-Log -Message "Show-SplashScreen function not found, skipping splash screen" -Level "Warning"
            }
        }
        
        # Check Azure connection
        $azureConnected = Get-AzureConnection
        if (-not $azureConnected) {
            Write-Log -Message "Not connected to Azure. Some functionality may be limited." -Level "Warning"
            # Continue anyway, as the user might not need Azure functionality right away
        }
        
        # Start main application loop
        $result = Start-MainLoop -DebugMode:$DebugMode
        
        # Log end of session
        $sessionDuration = (Get-Date) - $script:State.StartTime
        $formattedDuration = "{0:D2}:{1:D2}:{2:D2}" -f $sessionDuration.Hours, $sessionDuration.Minutes, $sessionDuration.Seconds
        
        Write-Log -Message "HomeLab session ended. Duration: $formattedDuration" -Level "Info"
        
        return $result
    }
    catch {
        $errorMessage = $_.Exception.Message
        $errorLine = $_.InvocationInfo.ScriptLineNumber
        $errorScript = $_.InvocationInfo.ScriptName
        
        if (Get-Command -Name Write-Log -ErrorAction SilentlyContinue) {
            Write-Log -Message "Error in Start-HomeLab: $errorMessage" -Level "Error"
            Write-Log -Message "Script: $errorScript, Line: $errorLine" -Level "Error"
        }
        else {
            Write-Host "ERROR: $errorMessage" -ForegroundColor Red
            Write-Host "Script: $errorScript, Line: $errorLine" -ForegroundColor Red
        }
        
        return $false
    }
}