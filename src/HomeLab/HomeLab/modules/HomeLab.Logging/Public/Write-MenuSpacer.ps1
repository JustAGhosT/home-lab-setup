function Write-MenuSpacer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Count = 1
    )
    
    for ($i = 0; $i -lt $Count; $i++) {
        Write-Host ""
    }
}