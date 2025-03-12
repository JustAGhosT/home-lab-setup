function Get-LogPath {
    [CmdletBinding()]
    param()
    
    return $Global:Config.LogFile
}
