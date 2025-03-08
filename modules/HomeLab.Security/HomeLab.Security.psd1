@{
    RootModule = 'HomeLab.Security.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'f8e4c230-5d7e-4b3a-9a1d-6c3e8b33e0f7'  # Generated new GUID
    Author = 'Jurie Smit'
    CompanyName = 'HomeLab'
    Copyright = '(c) 2025 Jurie Smit. All rights reserved.'
    Description = 'Security functions for HomeLab including VPN certificate and client management'
    PowerShellVersion = '5.1'
    
    # Modules that must be imported before this module
    RequiredModules = @('HomeLab.Core')
    
    # Functions to export
    FunctionsToExport = @(
        'New-VpnRootCertificate',
        'New-VpnClientCertificate',
        'New-AdditionalClientCertificate',
        'Add-VpnGatewayCertificate',
        'Get-VpnCertificate',
        'Add-VpnComputer',
        'Connect-Vpn',
        'Disconnect-Vpn',
        'Get-VpnConnectionStatus'
    )
    
    # Aliases to export
    AliasesToExport = @(
        'New-AdditionalClientCertificate'
    )
    
    PrivateData = @{
        PSData = @{
            Tags = @('HomeLab', 'Security', 'VPN')
            LicenseUri = 'https://github.com/JustAGhosT/homelab/LICENSE'
            ProjectUri = 'https://github.com/JustAGhosT/homelab'
            ReleaseNotes = 'Initial release of HomeLab.Security module'
        }
    }
}
