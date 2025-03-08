@{
    # The script module file associated with this manifest.
    RootModule         = 'HomeLab.psm1'
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules      = @(
        'modules\HomeLab.Core\HomeLab.Core.psm1'
        'modules\HomeLab.Azure\HomeLab.Azure.psm1'
        'modules\HomeLab.Security\HomeLab.Security.psm1'
        'modules\HomeLab.UI\HomeLab.UI.psm1'
        'modules\HomeLab.Monitoring\HomeLab.Monitoring.psm1'
        )

    # Version number of this module.
    ModuleVersion      = '1.0.0'
    
    # ID used to uniquely identify this module.
    GUID               = 'e1234567-e89b-12d3-a456-426614174000'
    
    # Author of this module.
    Author             = 'Jurie Smit'
    
    # Company or vendor of this module.
    CompanyName        = 'HomeLab'
    
    # Copyright statement for this module.
    Copyright          = '(c) 2025 Jurie Smit. All rights reserved.'
    
    # Description of the functionality provided by this module.
    Description        = 'Module for deploying and managing a home lab environment in Azure using a modular architecture. Includes infrastructure deployment, VPN setup, NAT gateway management, and more.'
    
    # Minimum version of the PowerShell engine required by this module.
    PowerShellVersion  = '5.1'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules    = @(
    )
    
    # Functions to export from this module.
    FunctionsToExport  = @(
        'Start-HomeLab'
    )
    
    # Cmdlets to export from this module.
    CmdletsToExport    = @()
    
    # Variables to export from this module.
    VariablesToExport  = @()
    
    # Aliases to export from this module.
    AliasesToExport    = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess.
    PrivateData = @{
        PSData = @{
            Tags         = @('HomeLab', 'Azure', 'Infrastructure', 'VPN', 'NAT', 'Security')
            LicenseUri   = 'https://github.com/JustAGhosT/home-lab-setup/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/JustAGhosT/home-lab-setup'
            ReleaseNotes = 'Initial release of HomeLab module with modular architecture'
        }
    }

    # Initialization script
    ScriptsToProcess = @('Initialize-HomeLab.ps1')
}
