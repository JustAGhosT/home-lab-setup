<#
.SYNOPSIS
    Displays a summary of the deployed resources.
.DESCRIPTION
    Presents a formatted summary of key deployment information such as resource group,
    VPN gateway name, location, environment, and the VPN client configuration file path.
.PARAMETER ResourceGroup
    The name of the resource group where resources were deployed.
.PARAMETER GatewayName
    The name of the VPN gateway.
.PARAMETER Location
    The Azure location where resources were deployed.
.PARAMETER Environment
    The environment (e.g., dev, test, prod).
.PARAMETER VpnConfigPath
    The path to the VPN client configuration file.
.EXAMPLE
    Show-DeploymentSummary -ResourceGroup "dev-saf-rg-homelab" -GatewayName "dev-saf-vpng-homelab" -Location "southafricanorth" -Environment "dev" -VpnConfigPath "C:\Deploy\vpnclientconfiguration.zip"
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Show-DeploymentSummary {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory=$true)]
        [string]$GatewayName,
        
        [Parameter(Mandatory=$true)]
        [string]$Location,
        
        [Parameter(Mandatory=$true)]
        [string]$Environment,
        
        [Parameter(Mandatory=$true)]
        [string]$VpnConfigPath
    )

    Write-Host "-----------------------------------------------------" -ForegroundColor Blue
    Write-Host "              DEPLOYMENT COMPLETED                 " -ForegroundColor Blue
    Write-Host "-----------------------------------------------------" -ForegroundColor Blue
    Write-Host "Summary of deployed resources:" -ForegroundColor Cyan
    Write-Host "* Resource Group: $ResourceGroup" -ForegroundColor White
    Write-Host "* VPN Gateway: $GatewayName" -ForegroundColor White
    Write-Host "* Location: $Location" -ForegroundColor White
    Write-Host "* Environment: $Environment" -ForegroundColor White
    Write-Host "* VPN Client Config: $VpnConfigPath" -ForegroundColor White
    Write-Host "" 
    Write-Host "Next Steps:" -ForegroundColor Green
    Write-Host "1. Extract the VPN client configuration ZIP file" -ForegroundColor White
    Write-Host "2. Install the VPN client configuration" -ForegroundColor White
    Write-Host "3. Connect to your Azure Home Lab environment" -ForegroundColor White
    Write-Host "Thank you for using the Azure Home Lab Deployment Tool!" -ForegroundColor Cyan
}
