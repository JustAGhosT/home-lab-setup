function Get-ConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $false)]
        $DefaultValue = $null
    )
    
    if ($Global:Config.ContainsKey($Key)) {
        return $Global:Config[$Key]
    }
    
    return $DefaultValue
}
