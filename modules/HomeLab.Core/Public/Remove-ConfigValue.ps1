function Remove-ConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $false)]
        [switch]$Save
    )
    
    if (-not $Global:Config.ContainsKey($Key)) {
        Write-SafeLog -Message "Configuration value '$Key' not found." -Level Warning
        return $false
    }
    
    $oldValue = $Global:Config[$Key]
    $Global:Config.Remove($Key)
    
    Write-SafeLog -Message "Configuration value '$Key' removed. Old value: '$oldValue'" -Level Info
    
    if ($Save) {
        Save-Configuration
    }
    
    return $true
}
