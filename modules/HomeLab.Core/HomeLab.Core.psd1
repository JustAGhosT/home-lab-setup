@{
    RootModule        = 'HomeLab.Core.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'e9c9b24d-6c07-4f6d-82e9-ffd481a5f9e2'
    Author            = 'Jurie Smit'
    CompanyName       = 'HomeLab'
    Copyright         = '(c) 2025 Jurie Smit. All rights reserved.'
    Description       = 'Core functionality for HomeLab including configuration management, logging, setup, and prerequisites'
    PowerShellVersion = '5.1'
    
    # Explicitly list all functions to export
    FunctionsToExport = @(
        'Import-Configuration',
        'Initialize-LogFile',
        'Write-Log',
        'Write-SimpleLog',
        'Test-Prerequisites',
        'Install-Prerequisites',
        'Test-SetupComplete',
        'Initialize-HomeLab',
        'Write-SafeLog',
        'Reset-Configuration',
        'Save-Configuration',
        'Import-ScriptFileSafely'
    )
    
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    
    # Private data
    PrivateData       = @{
        PSData = @{
            Tags         = @('HomeLab', 'Configuration', 'Logging', 'Setup', 'Azure')
            ProjectUri   = 'https://github.com/JustAGhosT/homelab'
            ReleaseNotes = 'Initial release of HomeLab.Core module'
        }
    }
}
