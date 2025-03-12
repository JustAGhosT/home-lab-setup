function Test-Configuration {
    [CmdletBinding()]
    param()
    
    $validationResults = @{
        IsValid           = $true
        MissingParameters = @()
        InvalidParameters = @()
    }
    
    # Required parameters
    $requiredParams = @('env', 'loc', 'project', 'location', 'LogFile', 'ConfigFile')
    
    # Valid values for certain parameters
    $validValues = @{
        env = @('dev', 'test', 'prod')
        loc = @('saf', 'we', 'ea')
    }
    
    # Check for missing parameters
    foreach ($param in $requiredParams) {
        if (-not $Global:Config.ContainsKey($param) -or [string]::IsNullOrEmpty($Global:Config[$param])) {
            $validationResults.IsValid = $false
            $validationResults.MissingParameters += $param
        }
    }
    
    # Check for invalid values
    foreach ($param in $validValues.Keys) {
        if ($Global:Config.ContainsKey($param) -and -not [string]::IsNullOrEmpty($Global:Config[$param])) {
            if ($validValues[$param] -notcontains $Global:Config[$param]) {
                $validationResults.IsValid = $false
                $validationResults.InvalidParameters += @{
                    Parameter   = $param
                    Value       = $Global:Config[$param]
                    ValidValues = $validValues[$param]
                }
            }
        }
    }
    
    return [PSCustomObject]$validationResults
}
