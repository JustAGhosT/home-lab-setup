function Reset-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Save
    )
    
    Write-SafeLog -Message "Resetting configuration to default values." -Level Info
    
    # Save the current ConfigFile path
    $configFile = $Global:Config.ConfigFile
    $logFile = $Global:Config.LogFile
    
    # Create default configuration
    $Global:Config = @{
        env        = "dev"
        loc        = "we"
        project    = "homelab"
        location   = "westeurope"
        LogFile    = $logFile
        ConfigFile = $configFile
        LastSetup  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    Write-SafeLog -Message "Configuration reset to default values." -Level Success
    
    if ($Save) {
        Save-Configuration
    }
    
    return $true
}
