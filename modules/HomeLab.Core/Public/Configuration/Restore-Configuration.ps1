function Restore-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupFile,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigFile = $Global:Config.ConfigFile
    )
    
    if (Test-Path $BackupFile) {
        try {
            # Create a backup of the current configuration before restoring
            Backup-Configuration -ConfigFile $ConfigFile | Out-Null
            
            # Restore from the backup file
            Copy-Item -Path $BackupFile -Destination $ConfigFile -Force
            
            # Reload the configuration
            Initialize-Configuration -ConfigFile $ConfigFile | Out-Null
            
            Write-SafeLog -Message "Configuration restored from $BackupFile." -Level Info
            return $true
        }
        catch {
            Write-SafeLog -Message "Error restoring configuration: $_" -Level Error
            return $false
        }
    }
    else {
        Write-SafeLog -Message "Backup file not found at $BackupFile." -Level Error
        return $false
    }
}
