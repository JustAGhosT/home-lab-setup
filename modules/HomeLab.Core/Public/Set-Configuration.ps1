function Set-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ConfigData,
        
        [Parameter(Mandatory = $false)]
        [switch]$Persist
    )
    
    # Update the global configuration with the provided data
    foreach ($key in $ConfigData.Keys) {
        $Global:Config[$key] = $ConfigData[$key]
    }
    
    Write-SafeLog -Message "Configuration updated with $(($ConfigData.Keys -join ', '))" -Level Info
    
    # Save the configuration if requested
    if ($Persist) {
        Save-Configuration
    }
}
