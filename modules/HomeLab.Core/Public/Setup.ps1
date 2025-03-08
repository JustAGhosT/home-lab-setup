<#
.SYNOPSIS
    Setup functions for HomeLab environment.
.DESCRIPTION
    Provides functions for initializing the HomeLab environment and checking if setup is complete.
.NOTES
    Author: Jurie Smit
    Date: March 7, 2025
#>

# Track initialization state to prevent recursion
if (-not (Get-Variable -Name HomeLab_Initializing -Scope Global -ErrorAction SilentlyContinue)) {
    $Global:HomeLab_Initializing = $false
}

<#
.SYNOPSIS
    Initializes the HomeLab setup.
.DESCRIPTION
    Creates the configuration file and sets up the initial configuration,
    including creating the configuration directory and logs directory.
.PARAMETER Force
    If specified, reinitializes the HomeLab setup even if it's already set up.
.EXAMPLE
    Initialize-HomeLab -Force
.NOTES
    Author: Jurie Smit
    Date: March 7, 2025
#>
function Setup-HomeLab {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Prevent recursive initialization
    if ($Global:HomeLab_Initializing) {
        Write-Warning "HomeLab initialization already in progress. Preventing recursive setup."
        return
    }
    
    $Global:HomeLab_Initializing = $true
    
    try {
        # Use Write-SimpleLog if Write-Log is not available
        $logFunction = Get-Command -Name Write-Log -ErrorAction SilentlyContinue
        if (-not $logFunction) {
            $logFunction = Get-Command -Name Write-SimpleLog -ErrorAction SilentlyContinue
        }
        
        # Create a wrapper function that maps parameters correctly
        function Write-SafeLog {
            param($Message, $Level)
            
            if ($logFunction.Name -eq 'Write-Log') {
                & $logFunction -Message $Message -Level $Level
            }
            else {
                # Map log levels to Write-SimpleLog format
                $simpleLevel = switch ($Level) {
                    'Info' { 'INFO' }
                    'Warning' { 'WARN' }
                    'Error' { 'ERROR' }
                    'Success' { 'SUCCESS' }
                    default { 'INFO' }
                }
                & $logFunction -Message $Message -Level $simpleLevel
            }
        }
        
        # Check if setup is already complete
        if ((Test-SetupComplete -Silent) -and -not $Force) {
            Write-SafeLog -Message "HomeLab setup is already complete. Use -Force to reinitialize." -Level Info
            
            # Just load the configuration if setup is complete
            if (Get-Command -Name Import-Configuration -ErrorAction SilentlyContinue) {
                Import-Configuration -Silent
            }
            
            # Initialize the log file if it doesn't exist
            if ($Global:Config -and $Global:Config.LogFile -and -not (Test-Path -Path $Global:Config.LogFile)) {
                if (Get-Command -Name Initialize-LogFile -ErrorAction SilentlyContinue) {
                    Initialize-LogFile
                }
            }
            
            return $true
        }
        
        Write-SafeLog -Message "Setting up HomeLab..." -Level Info
        
        # Create configuration directory
        $configDir = "$env:USERPROFILE\.homelab"
        if (-not (Test-Path $configDir)) {
            New-Item -Path $configDir -ItemType Directory -Force | Out-Null
            Write-SafeLog -Message "Created configuration directory: $configDir" -Level Info
        }
        
        # Create logs directory
        $logsDir = Join-Path -Path $configDir -ChildPath "logs"
        if (-not (Test-Path $logsDir)) {
            New-Item -Path $logsDir -ItemType Directory -Force | Out-Null
            Write-SafeLog -Message "Created logs directory: $logsDir" -Level Info
        }
        
        # Create default configuration file
        $configFile = Join-Path -Path $configDir -ChildPath "config.json"
        $defaultConfig = @{
            env        = "dev"
            loc        = "we"
            project    = "homelab"
            location   = "westeurope"
            LogFile    = Join-Path -Path $logsDir -ChildPath "homelab_$(Get-Date -Format 'yyyyMMdd').log"
            ConfigFile = $configFile
            LastSetup  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        # Update global configuration
        $Global:Config = $defaultConfig
        
        # Save configuration to file if the function exists
        if (Get-Command -Name Save-Configuration -ErrorAction SilentlyContinue) {
            Save-Configuration -ConfigFile $configFile
        }
        else {
            # Fallback if Save-Configuration doesn't exist
            $configJson = $defaultConfig | ConvertTo-Json
            Set-Content -Path $configFile -Value $configJson -Force
            Write-SafeLog -Message "Created configuration file using fallback method: $configFile" -Level Info
        }
        
        # Initialize the log file if the function exists
        if (Get-Command -Name Initialize-LogFile -ErrorAction SilentlyContinue) {
            Initialize-LogFile -LogFilePath $Global:Config.LogFile
        }
        
        Write-SafeLog -Message "HomeLab setup completed successfully." -Level Success
        return $true
    }
    finally {
        $Global:HomeLab_Initializing = $false
    }
}

<#
.SYNOPSIS
    Tests if the HomeLab setup is complete.
.DESCRIPTION
    Checks for the existence of the configuration file to determine if the setup has been completed.
.PARAMETER Silent
    If specified, suppresses log messages.
.EXAMPLE
    if (-not (Test-SetupComplete)) { Initialize-HomeLab }
.NOTES
    Author: Jurie Smit
    Date: March 7, 2025
#>
function Test-SetupComplete {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )
    
    # Use Write-SimpleLog if Write-Log is not available
    $logFunction = Get-Command -Name Write-Log -ErrorAction SilentlyContinue
    if (-not $logFunction) {
        $logFunction = Get-Command -Name Write-SimpleLog -ErrorAction SilentlyContinue
    }
    
    # Create a wrapper function that maps parameters correctly
    function Write-SafeLog {
        param($Message, $Level, [switch]$NoOutput)
        
        if ($NoOutput) {
            return
        }
        
        if ($logFunction.Name -eq 'Write-Log') {
            & $logFunction -Message $Message -Level $Level
        }
        else {
            # Map log levels to Write-SimpleLog format
            $simpleLevel = switch ($Level) {
                'Info' { 'INFO' }
                'Warning' { 'WARN' }
                'Error' { 'ERROR' }
                'Success' { 'SUCCESS' }
                default { 'INFO' }
            }
            & $logFunction -Message $Message -Level $simpleLevel
        }
    }
    
    $configFile = "$env:USERPROFILE\.homelab\config.json"
    $result = Test-Path $configFile
    
    if (-not $Silent) {
        if ($result) {
            Write-SafeLog -Message "HomeLab setup is complete." -Level Info
        }
        else {
            Write-SafeLog -Message "HomeLab setup is not complete." -Level Info
        }
    }
    
    return $result
}