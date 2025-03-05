@{
    # The script module file associated with this manifest.
    RootModule = 'HomeLab.psm1'
    
    # Version number of this module.
    ModuleVersion = '0.1.0'
    
    # ID used to uniquely identify this module
    GUID = 'e1234567-e89b-12d3-a456-426614174000'
    
    # Author of this module
    Author = 'Jurie Smit'
    
    # Company or vendor of this module
    CompanyName = 'HomeLab'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Jurie Smit. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Module for deploying and managing a home lab environment in Azure using a new modular infrastructure.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module. List only the public functions you wish to expose.
    FunctionsToExport = @(
        'Deploy-Infrastructure',
        'Invoke-DeployMenu',
        'Show-DeployMenu',
        'Get-Configuration',
        'Test-Prerequisites',
        'Install-Prerequisites',
        'Test-SetupComplete',
        'Initialize-HomeLab',
        'Start-HomeLab',
        'Write-Log'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            Tags = @('HomeLab', 'Azure', 'Infrastructure')
            ReleaseNotes = 'Initial release of HomeLab module refactored to a modular architecture'
        }
    }
}
