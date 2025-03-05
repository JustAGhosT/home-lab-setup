@{
    RootModule = 'HomeLab.Monitoring.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'c1234567-e89b-12d3-a456-426614174000'
    Author = 'Jurie Smit'
    CompanyName = 'HomeLab'
    Copyright = '(c) 2025 Jurie Smit. All rights reserved.'
    Description = 'Monitoring functionality for HomeLab setup'
    PowerShellVersion = '5.1'
    RequiredModules = @('HomeLab.Core') # This module depends on HomeLab.Core
    FunctionsToExport = '*' # Will be populated from Public folder
    PrivateData = @{
        PSData = @{
            Tags = @('HomeLab', 'Monitoring')
            ReleaseNotes = 'Initial release of HomeLab.Monitoring module'
        }
    }
}
