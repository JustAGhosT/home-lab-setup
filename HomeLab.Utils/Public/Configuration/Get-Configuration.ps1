<#
.SYNOPSIS
    Gets the current configuration.
.DESCRIPTION
    Returns the current global configuration object.
.EXAMPLE
    $config = Get-Configuration
.OUTPUTS
    Hashtable. Returns the global configuration hashtable.
.NOTES
    Author: Jurie Smit
    Date: March 8, 2025
#>
function Get-Configuration {
    [CmdletBinding()]
    param()
    
    return $Global:Config
}
