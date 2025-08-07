function Get-ConfigPath {
    [CmdletBinding()]
    param()
    
    return $Global:Config.ConfigFile
}
