function Set-ConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $true)]
        $Value,
        
        [Parameter(Mandatory = $false)]
        [switch]$Save
    )
    
    $oldValue = $null
    if ($Global:Config.ContainsKey($Key)) {
        $oldValue = $Global:Config[$Key]
    }
    
    $Global:Config[$Key] = $Value
    
    Write-SafeLog -Message "Configuration value '$Key' updated: '$oldValue' -> '$Value'" -Level Info
    
    if ($Save) {
        Save-Configuration
    }
    
    return $true
}
