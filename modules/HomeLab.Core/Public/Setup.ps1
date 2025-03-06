<#
.SYNOPSIS
    Setup functions for HomeLab environment.
.DESCRIPTION
    Provides functions for initializing the HomeLab environment and checking if setup is complete.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>

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
    Date: March 6, 2025
#>
function Initialize-HomeLab {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Check if setup is already complete
    if ((Test-SetupComplete) -and -not $Force) {
        Write-Log -Message "HomeLab setup is already complete. Use -Force to reinitialize." -Level Info
        return $true
    }
    
    Write-Log -Message "Initializing HomeLab setup..." -Level Info
    
    # Create configuration directory
    $configDir = "$env:USERPROFILE\.homelab"
    if (-not (Test-Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
        Write-Log -Message "Created configuration directory: $configDir" -Level Info
    }
    
    # Create logs directory
    $logsDir = Join-Path -Path $configDir -ChildPath "logs"
    if (-not (Test-Path $logsDir)) {
        New-Item -Path $logsDir -ItemType Directory -Force | Out-Null
        Write-Log -Message "Created logs directory: $logsDir" -Level Info
    }
    
    # Create default configuration file
    $configFile = Join-Path -Path $configDir -ChildPath "config.json"
    $defaultConfig = @{
        env       = "dev"
        loc       = "we"
        project   = "homelab"
        location  = "westeurope"
        LogFile   = Join-Path -Path $logsDir -ChildPath "homelab_$(Get-Date -Format 'yyyyMMdd').log"
        ConfigFile = $configFile
        LastSetup = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    # Update global configuration
    $Global:Config = $defaultConfig
    
    # Save configuration to file
    Save-Configuration -ConfigFile $configFile
    
    # Initialize the log file
    Initialize-LogFile -LogFilePath $Global:Config.LogFile
    
    Write-Log -Message "HomeLab setup initialized successfully." -Level Success
    return $true
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
    Date: March 6, 2025
#>
function Test-SetupComplete {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )
    
    $configFile = "$env:USERPROFILE\.homelab\config.json"
    $result = Test-Path $configFile
    
    if (-not $Silent) {
        if ($result) {
            Write-Log -Message "HomeLab setup is complete." -Level Info
        }
        else {
            Write-Log -Message "HomeLab setup is not complete." -Level Info
        }
    }
    
    return $result
}
