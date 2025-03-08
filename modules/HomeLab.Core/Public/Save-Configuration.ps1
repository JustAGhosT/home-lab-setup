function Save-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigFile = $Global:Config.ConfigFile,
        
        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )
    
    Write-SafeLog -Message "Saving configuration to $ConfigFile" -Level Info -NoOutput:$Silent
    
    try {
        # Create directory if it doesn't exist
        $configDir = Split-Path -Path $ConfigFile -Parent
        if (-not (Test-Path -Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        # Convert configuration to JSON and save
        $configJson = $Global:Config | ConvertTo-Json -Depth 5
        Set-Content -Path $ConfigFile -Value $configJson -Force
        
        Write-SafeLog -Message "Configuration saved successfully." -Level Success -NoOutput:$Silent
        return $true
    }
    catch {
        Write-SafeLog -Message "Failed to save configuration: $_" -Level Error -NoOutput:$Silent
        return $false
    }
}
