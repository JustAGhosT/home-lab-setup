@{
    # The script module file associated with this manifest.
    RootModule         = 'HomeLab.Core.psm1'
    
    # Version number of this module.
    ModuleVersion      = '1.0.0'
    
    # ID used to uniquely identify this module.
    GUID               = '12345678-1234-1234-1234-123456789abc'
    
    # Author of this module.
    Author             = 'Jurie Smit'
    
    # Company or vendor of this module.
    CompanyName        = 'HomeLab'
    
    # Copyright statement for this module.
    Copyright          = '(c) 2025 Jurie Smit. All rights reserved.'
    
    # Description of the functionality provided by this module.
    Description        = 'Core configuration and logging functions for HomeLab Setup.'
    
    # Minimum version of the PowerShell engine required by this module.
    PowerShellVersion  = '5.1'
    
    # Functions to export from this module.
    FunctionsToExport  = @(
        'Get-Configuration',
        'Initialize-HomeLab',
        'Install-Prerequisites',
        'Reset-Configuration',
        'Set-Configuration',
        'Test-Prerequisites',
        'Test-SetupComplete',
        'Update-ConfigurationParameter',
        'Write-Log'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess.
    PrivateData = @{
        PSData = @{
            Tags         = @('HomeLab', 'Configuration', 'Logging', 'Core')
            ReleaseNotes = 'Initial release of HomeLab.Core module'
        }
    }
}
