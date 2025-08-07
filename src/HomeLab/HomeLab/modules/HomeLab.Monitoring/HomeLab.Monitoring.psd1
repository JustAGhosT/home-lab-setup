@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'HomeLab.Monitoring.psm1'
    
    # Version number of this module.
    ModuleVersion = '0.1.0'
    
    # ID used to uniquely identify this module
    GUID = '5e9b2a7a-1f8d-4c41-a7c0-3f729c5e4b8d'
    
    # Author of this module
    Author = 'Jurie Smit'
    
    # Company or vendor of this module
    CompanyName = 'HomeLab'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Jurie Smit. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Provides monitoring and alerting capabilities for HomeLab environment'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{ModuleName = 'HomeLab.Core'; ModuleVersion = '0.1.0'},
        @{ModuleName = 'HomeLab.Azure'; ModuleVersion = '0.1.0'},
        @{ModuleName = 'Az'; ModuleVersion = '9.0.0'}
    )
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry
    FunctionsToExport = @(
        # Monitoring Functions
        'Start-ResourceMonitoring',
        'Get-ResourceMetrics',
        'Test-ResourceHealth',
        
        # Cost Functions
        'Get-CurrentCosts',
        'Get-CostForecast',
        'Export-CostReport',
        
        # Health Check Functions
        'Invoke-HealthCheck',
        'Get-HealthStatus',
        'Export-HealthReport',
        
        # Alerting Functions
        'Set-AlertRule',
        'Get-AlertRules',
        'Remove-AlertRule',
        'Test-AlertRule'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('HomeLab', 'Monitoring', 'Azure', 'Alerts')
            
            # A URL to the license for this module
            LicenseUri = 'https://github.com/JustAGhosT/azure-homelab-vpn/blob/main/LICENSE'
            
            # A URL to the main website for this project
            ProjectUri = 'https://github.com/JustAGhosT/azure-homelab-vpn'
        }
    }
}
