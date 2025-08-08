function Initialize-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigFile = $Global:Config.ConfigFile,
        
        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )
    
    Write-SafeLog -Message "Loading configuration from $ConfigFile" -Level Info -NoOutput:$Silent
    
    if (-not (Test-Path -Path $ConfigFile)) {
        Write-SafeLog -Message "Configuration file not found: $ConfigFile" -Level Warning -NoOutput:$Silent
        return $false
    }
    
    try {
        $configJson = Get-Content -Path $ConfigFile -Raw
        $config = $configJson | ConvertFrom-Json -AsHashtable
        
        # Update global configuration
        foreach ($key in $config.Keys) {
            $Global:Config[$key] = $config[$key]
        }
        
        Write-SafeLog -Message "Configuration loaded successfully." -Level Success -NoOutput:$Silent
        return $true
    }
    catch {
        Write-SafeLog -Message "Failed to load configuration: $_" -Level Error -NoOutput:$Silent
        return $false
    }
}
