@{
    # The script module file associated with this manifest.
    RootModule         = 'HomeLab.Security.psm1'
    
    # Version number of this module.
    ModuleVersion      = '1.0.0'
    
    # ID used to uniquely identify this module.
    GUID               = 'd1234567-e89b-12d3-a456-426614174000'
    
    # Author of this module.
    Author             = 'Jurie Smit'
    
    # Company or vendor of this module.
    CompanyName        = 'HomeLab'
    
    # Copyright statement for this module.
    Copyright          = '(c) 2025 Jurie Smit. All rights reserved.'
    
    # Description of the functionality provided by this module.
    Description        = 'Security functionality for HomeLab setup, including VPN certificate management and VPN client management.'
    
    # Minimum version of the PowerShell engine required by this module.
    PowerShellVersion  = '5.1'
    
    # This module depends on HomeLab.Core.
    RequiredModules    = @('HomeLab.Core')
    
    # Export all functions from the Public folder.
    FunctionsToExport  = '*'
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess.
    PrivateData = @{
        PSData = @{
            Tags         = @('HomeLab', 'Security')
            ReleaseNotes = 'Initial release of HomeLab.Security module'
        }
    }
}
