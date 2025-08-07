@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'HomeLab.psm1'
    
    # Version number of this module.
    ModuleVersion     = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    
    # Author of this module
    Author            = 'Jurie Smit'
    
    # Company or vendor of this module
    CompanyName       = 'HomeLab'
    
    # Copyright statement for this module
    Copyright         = '(c) 2025 Jurie Smit. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description       = 'Comprehensive Azure HomeLab setup and management module with VPN, website deployment, DNS management, and monitoring capabilities'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules   = @()
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules     = @(
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
    CmdletsToExport   = @()
    
    # Variables to export from this module
    VariablesToExport = '*'
    
    # Aliases to export from this module
    AliasesToExport   = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData       = @{
        PSData = @{
            # Tags applied to this module
            Tags         = @('HomeLab', 'Azure', 'Infrastructure', 'VPN', 'DNS', 'WebDeployment', 'Monitoring', 'PowerShell')

            # A URL to the license for this module
            LicenseUri   = 'https://github.com/JustAGhosT/home-lab-setup/blob/main/LICENSE'

            # A URL to the main website for this project
            ProjectUri   = 'https://github.com/JustAGhosT/home-lab-setup'

            # A URL to an icon representing this module
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'v1.0.0 - Initial release with comprehensive Azure HomeLab management capabilities including VPN, DNS, website deployment, and monitoring features. See CHANGELOG.md for full details.'
        }
    }
    
    # Initialization script
    ScriptsToProcess  = @('functions/Start-HomeLab.ps1')
}
