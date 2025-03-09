function Test-SetupComplete {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )
    
    # Use Write-SimpleLog if Write-Log is not available
    $logFunction = Get-Command -Name Write-Log -ErrorAction SilentlyContinue
    if (-not $logFunction) {
        $logFunction = Get-Command -Name Write-SimpleLog -ErrorAction SilentlyContinue
    }
    
    # Create a wrapper function that maps parameters correctly
    function Write-SafeLog {
        param($Message, $Level, [switch]$NoOutput)
        
        if ($NoOutput) {
            return
        }
        
        if ($logFunction.Name -eq 'Write-Log') {
            & $logFunction -Message $Message -Level $Level
        }
        else {
            # Map log levels to Write-SimpleLog format
            $simpleLevel = switch ($Level) {
                'Info' { 'INFO' }
                'Warning' { 'WARN' }
                'Error' { 'ERROR' }
                'Success' { 'SUCCESS' }
                default { 'INFO' }
            }
            & $logFunction -Message $Message -Level $simpleLevel
        }
    }
    
    $configFile = "$env:USERPROFILE\.homelab\config.json"
    $result = Test-Path $configFile
    
    if (-not $Silent) {
        if ($result) {
            Write-SafeLog -Message "HomeLab setup is complete." -Level Info
        }
        else {
            Write-SafeLog -Message "HomeLab setup is not complete." -Level Info
        }
    }
    
    return $result
}
