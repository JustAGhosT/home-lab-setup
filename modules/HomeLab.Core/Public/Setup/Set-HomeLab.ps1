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
                    'Warning' { 'Warning' }
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
                if (Get-Command -Name Initialize-Logging -ErrorAction SilentlyContinue) {
                    Initialize-Logging
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
            loc        = "saf"
            project    = "homelab"
            location   = "southafricanorth"
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
        if (Get-Command -Name Initialize-Logging -ErrorAction SilentlyContinue) {
            Initialize-Logging -LogFilePath $Global:Config.LogFile
        }
        
        Write-SafeLog -Message "HomeLab setup completed successfully." -Level Success
        return $true
    }
    finally {
        $Global:HomeLab_Initializing = $false
    }
}
