@{
    # The script module file associated with this manifest.
    RootModule        = 'HomeLab.Azure.psm1'
    
    # Version number of this module.
    ModuleVersion     = '1.0.0'
    
    # ID used to uniquely identify this module.
    GUID              = 'b1234567-e89b-12d3-a456-426614174000'
    
    # Author of this module.
    Author            = 'Jurie Smit'
    
    # Company or vendor of this module.
    CompanyName       = 'HomeLab'
    
    # Copyright statement for this module.
    Copyright         = '(c) 2025 Jurie Smit. All rights reserved.'
    
    # Description of the functionality provided by this module.
    Description       = 'Azure infrastructure deployment for HomeLab'
    
    # Minimum version of the PowerShell engine required by this module.
    PowerShellVersion = '5.1'
    
    # This module depends on all HomeLab modules
    RequiredModules   = @(
    )
    
    # Functions to export
    FunctionsToExport = @(
        'Deploy-Infrastructure',
        'Set-VpnGatewayState',
        'Get-VpnGatewayState',
        'Test-ResourceGroup',
        'Connect-AzureAccount',
        'Reset-ResourceGroup',
        'Monitor-AzureResourceDeployment',
        'Start-BackgroundMonitoring',
        'Show-BackgroundMonitoringDetails',
        'Get-BackgroundMonitoringJobs',
        'Get-BackgroundJobStatus',
        'Get-VpnGatewayJobStatus',
        'Show-BackgroundJobInfo',
        'Export-JobInfo',
        'Set-VpnSplitTunneling',
        'NatGatewayEnableDisable'
    )
    
    # Cmdlets to export
    CmdletsToExport   = @()
    
    # Variables to export
    VariablesToExport = @()
    
    # Aliases to export
    AliasesToExport   = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess.
    PrivateData       = @{
        PSData = @{
            Tags         = @('HomeLab', 'Azure', 'Infrastructure')
            ProjectUri   = 'https://github.com/JustAGhosT/homelab'
            ReleaseNotes = 'Initial release of HomeLab.Azure module'
        }
    }
}
