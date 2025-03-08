function Backup-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigFile = $Global:Config.ConfigFile
    )
    
    if (Test-Path $ConfigFile) {
        try {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $backupDir = Join-Path -Path (Split-Path -Parent $ConfigFile) -ChildPath "Backups"
            
            if (-not (Test-Path $backupDir)) {
                New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
            }
            
            $backupFile = Join-Path -Path $backupDir -ChildPath "config_$timestamp.json"
            Copy-Item -Path $ConfigFile -Destination $backupFile -Force
            
            Write-SafeLog -Message "Configuration backed up to $backupFile." -Level Info
            return $backupFile
        }
        catch {
            Write-SafeLog -Message "Error backing up configuration: ${_}" -Level Error
            return $null
        }
    }
    else {
        Write-SafeLog -Message "Configuration file not found at $ConfigFile." -Level Error
        return $null
    }
}
