@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'HomeLab.psm1'
    
    # Version number of this module.
    ModuleVersion = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID = '12345678-1234-1234-1234-123456789abc'  # Replace with a new GUID
    
    # Author of this module
    Author = 'Jurie Smit'
    
    # Company or vendor of this module
    CompanyName = 'HomeLab'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Jurie Smit. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'HomeLab management module for Azure infrastructure'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @(
        'modules\HomeLab.Logging\HomeLab.Logging.psm1',
        'modules\HomeLab.Utils\HomeLab.Utils.psm1',
        'modules\HomeLab.Core\HomeLab.Core.psm1',
        'modules\HomeLab.Azure\HomeLab.Azure.psm1',
        'modules\HomeLab.UI\HomeLab.UI.psm1',
        'modules\HomeLab.Security\HomeLab.Security.psm1',
        'modules\HomeLab.Monitoring\HomeLab.Monitoring.psm1'
    )
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry
    # FunctionsToExport = @(
    # )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = '*'
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('HomeLab', 'Azure', 'Infrastructure')
            
            # A URL to the license for this module
            # LicenseUri = ''
            
            # A URL to the main website for this project
            # ProjectUri = ''
            
            # A URL to an icon representing this module
            # IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of HomeLab module'
        }
    }
    
    # Initialization script
    ScriptsToProcess = @('functions/Start-HomeLab.ps1')
}
