@{
    RootModule = 'HomeLab.Core.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'a1b2c3d4-e5f6-4a5b-9c8d-7e6f5a4b3c2d'  # Generate a new GUID
    Author = 'Jurie Smit'
    CompanyName = 'HomeLab'
    Copyright = '(c) 2025 Jurie Smit. All rights reserved.'
    Description = 'Core functionality for HomeLab including configuration management, logging, setup, and prerequisites.'
    PowerShellVersion = '5.1'
    
    # Functions to export from this module - use wildcard for automatic export
    FunctionsToExport = '*'
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('HomeLab', 'Configuration', 'Logging')
            
            # A URL to the license for this module
            LicenseUri = ''
            
            # A URL to the main website for this project
            ProjectUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of HomeLab.Core module'
        }
    }
}
