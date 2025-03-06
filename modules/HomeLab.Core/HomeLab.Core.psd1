@{
    RootModule = 'HomeLab.Core.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'e9c9b24d-6c07-4f6d-82e9-ffd481a5f9e2'
    Author = 'Jurie Smit'
    CompanyName = 'HomeLab'
    Copyright = '(c) 2025 Jurie Smit. All rights reserved.'
    Description = 'Core functionality for HomeLab including configuration management, logging, setup, and prerequisites'
    PowerShellVersion = '5.1'
    
    # Functions to export
    FunctionsToExport = @(
        # Configuration functions
        'Get-Configuration',
        'Update-ConfigurationParameter',
        'Load-Configuration',
        'Save-Configuration',
        'Reset-Configuration',
        'Set-Configuration',
        'Test-Configuration',
        'Backup-Configuration',
        'Restore-Configuration',
        'Export-HomelabConfiguration',
        'Import-HomelabConfiguration',
        
        # Logging functions
        'Initialize-LogFile',
        'Write-Log',
        'Set-LogLevel',
        'Rotate-LogFile',
        'Get-LogEntries',
        'Get-LogPath',
        'Set-LogPath',
        
        # Setup functions
        'Initialize-HomeLab',
        'Test-SetupComplete',
        
        # Prerequisites functions
        'Install-Prerequisites',
        'Test-Prerequisites'
    )
    
    # Cmdlets to export
    CmdletsToExport = @()
    
    # Variables to export
    VariablesToExport = @()
    
    # Aliases to export
    AliasesToExport = @()
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('HomeLab', 'Configuration', 'Logging', 'Setup', 'Azure')
            ProjectUri = 'https://github.com/JustAGhosT/homelab'
            ReleaseNotes = 'Initial release of HomeLab.Core module'
        }
    }
}
