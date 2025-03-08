@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'HomeLab.UI.psm1'
    
    # Version number of this module.
    ModuleVersion = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID = '8a7b1a1e-5c4d-4f2b-9d8a-f5e9c8b3e6d7'
    
    # Author of this module
    Author = 'Jurie Smit'
    
    # Company or vendor of this module
    CompanyName = ''
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Jurie Smit. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'User interface module for HomeLab Azure deployment and management'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        # Main functions
        'Show-MainMenu',
        'Show-Menu',
        'Show-DeploymentSummary',
        
        # Menu display functions
        'Show-DeployMenu',
        'Show-VpnCertMenu',
        'Show-VpnGatewayMenu',
        'Show-VpnClientMenu',
        'Show-NatGatewayMenu',
        'Show-DocumentationMenu',
        'Show-SettingsMenu',
        
        # Menu handler functions
        'Invoke-DeployMenu',
        'Invoke-VpnCertMenu',
        'Invoke-VpnGatewayMenu',
        'Invoke-VpnClientMenu',
        'Invoke-NatGatewayMenu',
        'Invoke-DocumentationMenu',
        'Invoke-SettingsMenu'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Azure', 'HomeLab', 'VPN', 'UI')
            
            # A URL to the license for this module.
            LicenseUri = ''
            
            # A URL to the main website for this project.
            ProjectUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of HomeLab.UI module.'
        }
    }
}
