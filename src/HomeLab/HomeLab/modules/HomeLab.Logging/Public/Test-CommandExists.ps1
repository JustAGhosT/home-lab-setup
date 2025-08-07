<#
.SYNOPSIS
    Tests if a PowerShell command exists
.DESCRIPTION
    Checks if a specified command (cmdlet, function, alias) exists in the current session.
    Returns a boolean indicating whether the command exists.
.PARAMETER CommandName
    The name of the command to check
.EXAMPLE
    Test-CommandExists -CommandName "Get-Process"
    Returns $true because Get-Process is a built-in cmdlet
.NOTES
    Part of the HomeLab.Core module
#>
function Test-CommandExists {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )
    
    $command = Get-Command -Name $CommandName -ErrorAction SilentlyContinue
    return ($null -ne $command)
}

# Export the function
Export-ModuleMember -Function Test-CommandExists
