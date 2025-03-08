@{
    RootModule = 'HomeLab.Utils.psm1'
    ModuleVersion = '0.1.0'
    GUID = ''
    Author = 'Jurie Smit'
    CompanyName = 'HomeLab'
    Copyright = '(c) 2025 Jurie Smit. All rights reserved.'
    Description = 'Utility functions for HomeLab environment'
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Get-Configuration',
        'Split-FunctionsToFiles'
    )
    
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
            Tags = @('HomeLab', 'Utility', 'Tools')
            
            # A URL to the license for this module
            LicenseUri = ''
            
            # A URL to the main website for this project
            ProjectUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of HomeLab.Utils module'
        }
    }
}
