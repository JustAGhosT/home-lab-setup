@{
    RootModule = 'DeploymentModule.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-47a8-9b0c-1d2e3f4a5b6c'  # Generate a new GUID
    Author = 'Jurie Smit'
    CompanyName = 'HomeLab'
    Copyright = '(c) 2025 Jurie Smit. All rights reserved.'
    Description = 'Module for handling Azure deployments for HomeLab setup'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Invoke-DeployMenu',
        'Invoke-FullDeployment',
        'Invoke-NetworkDeployment',
        'Invoke-VPNGatewayDeployment',
        'Invoke-NATGatewayDeployment',
        'Show-DeploymentStatus',
        'Show-BackgroundMonitoringDetails'
    )
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Azure', 'Deployment', 'HomeLab')
            ProjectUri = ''
            LicenseUri = ''
            ReleaseNotes = 'Initial release'
        }
    }
}
