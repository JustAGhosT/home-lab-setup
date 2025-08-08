@{
    RootModule = 'HomeLab.DNS.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'a7c3e9f1-d2b4-4c5e-8f6a-7b8d9c0e1f2a'
    Author = 'Jurie Smit'
    CompanyName = 'HomeLab'
    Copyright = '(c) 2023. All rights reserved.'
    Description = 'DNS zone management and configuration for HomeLab'
    PowerShellVersion = '7.0'
    RequiredModules = @(
        @{ModuleName = 'HomeLab.Core'; ModuleVersion = '0.1.0'}, 
        @{ModuleName = 'HomeLab.Azure'; ModuleVersion = '0.1.0'}
    )
    FunctionsToExport = @(
        'Add-DNSRecord',
        'Get-DNSRecords',
        'New-DNSZone'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('HomeLab', 'Azure', 'DNS', 'Zone')
            ProjectUri = 'https://github.com/JustAGhosT/azure-homelab-setup'
        }
    }
}