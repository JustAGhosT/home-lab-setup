@{
    RootModule = 'HomeLab.Web.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'f8e9a9d2-e8c1-4d3f-9e1a-8c5d7b8e3f2a'
    Author = 'Jurie Smit'
    CompanyName = 'HomeLab'
    Copyright = '(c) 2023. All rights reserved.'
    Description = 'Website deployment and hosting functionality for HomeLab'
    PowerShellVersion = '7.0'
    RequiredModules = @('HomeLab.Core', 'HomeLab.Azure')
    FunctionsToExport = '*'
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('HomeLab', 'Azure', 'Website', 'Deployment')
            ProjectUri = 'https://github.com/JustAGhosT/azure-homelab-setup'
        }
    }
}