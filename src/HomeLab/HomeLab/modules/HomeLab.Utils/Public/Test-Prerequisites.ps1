function Test-Prerequisites {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )
    
    Write-SafeLog -Message "Checking prerequisites..." -Level Info -NoOutput:$Silent
    
    # Check if Azure CLI is installed
    $azCliInstalled = $null -ne (Get-Command az -ErrorAction SilentlyContinue)
    if (-not $azCliInstalled) {
        Write-SafeLog -Message "Azure CLI is not installed." -Level Warning -NoOutput:$Silent
    }
    
    # Check if Az PowerShell module is installed
    $azPowerShellInstalled = $null -ne (Get-Module -ListAvailable Az.Accounts)
    if (-not $azPowerShellInstalled) {
        Write-SafeLog -Message "Az PowerShell module is not installed." -Level Warning -NoOutput:$Silent
    }
    
    $allInstalled = $azCliInstalled -and $azPowerShellInstalled
    
    if ($allInstalled) {
        Write-SafeLog -Message "All prerequisites are installed." -Level Success -NoOutput:$Silent
    }
    
    return $allInstalled
}
