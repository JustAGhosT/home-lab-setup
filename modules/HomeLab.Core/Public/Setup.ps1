<#
.SYNOPSIS
    Initializes the HomeLab setup.
.DESCRIPTION
    Creates the configuration file and sets up the initial configuration,
    including creating the configuration directory and logs directory.
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>
function Initialize-HomeLab {
    [CmdletBinding()]
    param()
    
    Write-Log -Message "Initializing HomeLab setup..." -Level INFO
    
    # Create configuration directory
    $configDir = "$env:USERPROFILE\.homelab"
    if (-not (Test-Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
        Write-Log -Message "Created configuration directory: $configDir" -Level INFO
    }
    
    # Create default configuration file
    $configFile = Join-Path -Path $configDir -ChildPath "config.json"
    $defaultConfig = @{
        env       = "dev"
        loc       = "we"
        project   = "homelab"
        location  = "westeurope"
        LogFile   = "$(Get-Location)\logs\homelab_$(Get-Date -Format 'yyyyMMdd').log"
        LastSetup = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $defaultConfig | ConvertTo-Json | Out-File -FilePath $configFile -Force
    Write-Log -Message "Created default configuration file: $configFile" -Level INFO
    
    # Create logs directory
    $logsDir = "$(Get-Location)\logs"
    if (-not (Test-Path $logsDir)) {
        New-Item -Path $logsDir -ItemType Directory -Force | Out-Null
        Write-Log -Message "Created logs directory: $logsDir" -Level INFO
    }
    
    Write-Log -Message "HomeLab setup initialized successfully." -Level SUCCESS
    return $true
}

<#
.SYNOPSIS
    Tests if the HomeLab setup is complete.
.DESCRIPTION
    Checks for the existence of the configuration file to determine if the setup has been completed.
.EXAMPLE
    if (-not (Test-SetupComplete)) { Initialize-HomeLab }
#>
function Test-SetupComplete {
    [CmdletBinding()]
    param()
    
    $configFile = "$env:USERPROFILE\.homelab\config.json"
    $result = Test-Path $configFile
    
    if ($result) {
        Write-Log -Message "HomeLab setup is complete." -Level INFO
    }
    else {
        Write-Log -Message "HomeLab setup is not complete." -Level INFO
    }
    
    return $result
}

Export-ModuleMember -Function Initialize-HomeLab, Test-SetupComplete
