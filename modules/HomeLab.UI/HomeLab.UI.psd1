@{
    # The script module file associated with this manifest.
    RootModule         = 'HomeLab.UI.psm1'
    
    # Version number of this module.
    ModuleVersion      = '1.0.0'
    
    # ID used to uniquely identify this module.
    GUID               = '87654321-4321-4321-4321-cba987654321'
    
    # Author of this module.
    Author             = 'Jurie Smit'
    
    # Company or vendor of this module.
    CompanyName        = 'HomeLab'
    
    # Copyright statement for this module.
    Copyright          = '(c) 2025 Jurie Smit. All rights reserved.'
    
    # Description of the functionality provided by this module.
    Description        = 'UI helper functions and menu functionality for HomeLab Setup.'
    
    # Minimum version of the PowerShell engine required by this module.
    PowerShellVersion  = '5.1'
    
    # Functions to export from this module.
    FunctionsToExport  = @(
         'Pause',
         'Show-Spinner',
         'Get-UserConfirmation',
         'Show-Menu',
         'Show-MainMenu',
         'Show-DeployMenu',
         'Show-VpnCertMenu',
         'Show-VpnGatewayMenu',
         'Show-VpnClientMenu',
         'Show-NatGatewayMenu',
         'Show-DocumentationMenu',
         'Show-SettingsMenu',
         'Show-DeploymentSummary',
         'Invoke-DeployMenu',
         'Invoke-VpnCertMenu',
         'Invoke-VpnGatewayMenu',
         'Invoke-VpnClientMenu',
         'Invoke-NatGatewayMenu',
         'Invoke-DocumentationMenu',
         'Invoke-SettingsMenu'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess.
    PrivateData = @{
        PSData = @{
            Tags         = @('HomeLab', 'UI', 'Menu', 'User Interface')
            ProjectUri   = 'https://github.com/JustAGhosT/homelab'
            ReleaseNotes = 'Initial release of HomeLab.UI module'
        }
    }
}
