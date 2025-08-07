<#
.SYNOPSIS
    Gets the resource type for a given resource.
.DESCRIPTION
    Gets the resource type for a given resource by parsing the resource ID.
.PARAMETER ResourceId
    The resource ID.
.EXAMPLE
    Get-ResourceType -ResourceId "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/HomeLab-RG/providers/Microsoft.Compute/virtualMachines/vm1"
#>
function Get-ResourceType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId
    )
    
    $resourceTypePattern = '/providers/([^/]+/[^/]+)/'
    if ($ResourceId -match $resourceTypePattern) {
        return $matches[1]
    }
    
    return $null
}

<#
.SYNOPSIS
    Gets the resource name for a given resource.
.DESCRIPTION
    Gets the resource name for a given resource by parsing the resource ID.
.PARAMETER ResourceId
    The resource ID.
.EXAMPLE
    Get-ResourceName -ResourceId "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/HomeLab-RG/providers/Microsoft.Compute/virtualMachines/vm1"
#>
function Get-ResourceName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceId
    )
    
    $resourceNamePattern = '/([^/]+)$'
    if ($ResourceId -match $resourceNamePattern) {
        return $matches[1]
    }
    
    return $null
}

<#
.SYNOPSIS
    Formats a time span as a human-readable string.
.DESCRIPTION
    Formats a time span as a human-readable string.
.PARAMETER TimeSpan
    The time span to format.
.EXAMPLE
    Format-TimeSpan -TimeSpan (New-TimeSpan -Days 1 -Hours 2 -Minutes 30)
#>
function Format-TimeSpan {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [TimeSpan]$TimeSpan
    )
    
    $parts = @()
    
    if ($TimeSpan.Days -gt 0) {
        $parts += "$($TimeSpan.Days) day$(if ($TimeSpan.Days -ne 1) { 's' })"
    }
    
    if ($TimeSpan.Hours -gt 0) {
        $parts += "$($TimeSpan.Hours) hour$(if ($TimeSpan.Hours -ne 1) { 's' })"
    }
    
    if ($TimeSpan.Minutes -gt 0) {
        $parts += "$($TimeSpan.Minutes) minute$(if ($TimeSpan.Minutes -ne 1) { 's' })"
    }
    
    if ($TimeSpan.Seconds -gt 0 -and $parts.Count -eq 0) {
        $parts += "$($TimeSpan.Seconds) second$(if ($TimeSpan.Seconds -ne 1) { 's' })"
    }
    
    if ($parts.Count -eq 0) {
        return "0 seconds"
    }
    
    return $parts -join ", "
}

<#
.SYNOPSIS
    Gets the appropriate color for a status.
.DESCRIPTION
    Gets the appropriate color for a status.
.PARAMETER Status
    The status to get the color for.
.EXAMPLE
    Get-StatusColor -Status "Healthy"
#>
function Get-StatusColor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Status
    )
    
    switch ($Status) {
        "Healthy" { return "Green" }
        "Warning" { return "Yellow" }
        "Unhealthy" { return "Red" }
        "Error" { return "Red" }
        "Unknown" { return "Gray" }
        default { return "White" }
    }
}

<#
.SYNOPSIS
    Formats a file size as a human-readable string.
.DESCRIPTION
    Formats a file size as a human-readable string.
.PARAMETER Bytes
    The size in bytes.
.EXAMPLE
    Format-FileSize -Bytes 1024
#>
function Format-FileSize {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [long]$Bytes
    )
    
    $sizes = @("B", "KB", "MB", "GB", "TB", "PB")
    $order = 0
    
    while ($Bytes -ge 1024 -and $order -lt $sizes.Count - 1) {
        $Bytes /= 1024
        $order++
    }
    
    return "{0:0.##} {1}" -f $Bytes, $sizes[$order]
}

<#
.SYNOPSIS
    Gets the month name from a month number.
.DESCRIPTION
    Gets the month name from a month number.
.PARAMETER MonthNumber
    The month number (1-12).
.EXAMPLE
    Get-MonthName -MonthNumber 1
#>
function Get-MonthName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 12)]
        [int]$MonthNumber
    )
    
    $months = @(
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    )
    
    return $months[$MonthNumber - 1]
}
