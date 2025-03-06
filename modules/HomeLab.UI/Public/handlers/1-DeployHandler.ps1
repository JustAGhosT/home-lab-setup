<#
.SYNOPSIS
    Handles the deployment menu
.DESCRIPTION
    Processes user selections in the deployment menu
.EXAMPLE
    Invoke-DeployMenu
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Invoke-DeployMenu {
    [CmdletBinding()]
    param()
    
    $selection = 0
    do {
        Show-DeployMenu
        $selection = Read-Host "Select an option"
        $config = Get-Configuration
        
        switch ($selection) {
            "1" {
                Write-Host "Starting full deployment..." -ForegroundColor Cyan
                Deploy-Infrastructure
                Pause
            }
            "2" {
                Write-Host "Deploying network only..." -ForegroundColor Cyan
                Deploy-Infrastructure -ComponentsOnly "network"
                Pause
            }
            "3" {
                Write-Host "Deploying VPN Gateway only..." -ForegroundColor Cyan
                Deploy-Infrastructure -ComponentsOnly "vpngateway"
                Pause
            }
            "4" {
                Write-Host "Deploying NAT Gateway only..." -ForegroundColor Cyan
                Deploy-Infrastructure -ComponentsOnly "natgateway"
                Pause
            }
            "5" {
                Write-Host "Checking deployment status..." -ForegroundColor Cyan
                $resourceGroup = "$($config.env)-$($config.loc)-rg-$($config.project)"
                $status = az group show --name $resourceGroup --query "properties.provisioningState" -o tsv 2>$null
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Resource Group Status: $status" -ForegroundColor Green
                    
                    # Check status of key resources
                    Write-Host "Checking key resources..." -ForegroundColor Yellow
                    
                    # Check VNet
                    $vnetName = "$($config.env)-$($config.loc)-vnet-$($config.project)"
                    $vnetStatus = az network vnet show --resource-group $resourceGroup --name $vnetName --query "provisioningState" -o tsv 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "Virtual Network: $vnetStatus" -ForegroundColor White
                    }
                    
                    # Check VPN Gateway
                    $vpnGatewayName = "$($config.env)-$($config.loc)-vpng-$($config.project)"
                    $vpnStatus = az network vnet-gateway show --resource-group $resourceGroup --name $vpnGatewayName --query "provisioningState" -o tsv 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "VPN Gateway: $vpnStatus" -ForegroundColor White
                    }
                    
                    # Check NAT Gateway
                    $natGatewayName = "$($config.env)-$($config.loc)-natgw-$($config.project)"
                    $natStatus = az network nat gateway show --resource-group $resourceGroup --name $natGatewayName --query "provisioningState" -o tsv 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "NAT Gateway: $natStatus" -ForegroundColor White
                    }
                }
                else {
                    Write-Host "Resource group not found or error retrieving status." -ForegroundColor Red
                }
                
                Pause
            }
            "0" {
                # Return to main menu (do nothing here)
            }
            default {
                Write-Host "Invalid option. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($selection -ne "0")
}
