<#
.SYNOPSIS
    NAT Gateway Menu Handler for HomeLab Setup
.DESCRIPTION
    Processes user selections in the NAT gateway menu using the new modular structure.
    Options include enabling/disabling the NAT Gateway and checking its status.
.EXAMPLE
    Invoke-NatGatewayMenu
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Invoke-NatGatewayMenu {
    [CmdletBinding()]
    param()
    
    $selection = 0
    do {
        Show-NatGatewayMenu
        $selection = Read-Host "Select an option"
        $config = Get-Configuration
        $resourceGroup = "$($config.env)-$($config.loc)-rg-$($config.project)"
        
        switch ($selection) {
            "1" {
                Write-Host "Enabling NAT Gateway..." -ForegroundColor Cyan
                
                # Assuming NatGatewayEnableDisable is defined in another module
                if (Get-Command NatGatewayEnableDisable -ErrorAction SilentlyContinue) {
                    NatGatewayEnableDisable -Enable -ResourceGroup $resourceGroup
                }
                else {
                    Write-Host "Function NatGatewayEnableDisable not found. Make sure the required module is imported." -ForegroundColor Red
                    
                    # Fallback to direct Azure CLI command
                    $natGatewayName = "$($config.env)-$($config.loc)-natgw-$($config.project)"
                    $vnetName = "$($config.env)-$($config.loc)-vnet-$($config.project)"
                    $subnetNames = @("$($config.env)-$($config.project)-snet-default", "$($config.env)-$($config.project)-snet-app")
                    
                    Write-Host "Attempting to use Azure CLI directly..." -ForegroundColor Yellow
                    foreach ($subnet in $subnetNames) {
                        Write-Host "Enabling NAT Gateway for subnet $subnet..." -ForegroundColor White
                        $result = az network vnet subnet update --resource-group $resourceGroup --vnet-name $vnetName --name $subnet --nat-gateway $natGatewayName
                        
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "NAT Gateway enabled for subnet $subnet." -ForegroundColor Green
                        }
                        else {
                            Write-Host "Failed to enable NAT Gateway for subnet $subnet." -ForegroundColor Red
                        }
                    }
                }
                
                Pause
            }
            "2" {
                Write-Host "Disabling NAT Gateway..." -ForegroundColor Cyan
                
                # Assuming NatGatewayEnableDisable is defined in another module
                if (Get-Command NatGatewayEnableDisable -ErrorAction SilentlyContinue) {
                    NatGatewayEnableDisable -Disable -ResourceGroup $resourceGroup
                }
                else {
                    Write-Host "Function NatGatewayEnableDisable not found. Make sure the required module is imported." -ForegroundColor Red
                    
                    # Fallback to direct Azure CLI command
                    $vnetName = "$($config.env)-$($config.loc)-vnet-$($config.project)"
                    $subnetNames = @("$($config.env)-$($config.project)-snet-default", "$($config.env)-$($config.project)-snet-app")
                    
                    Write-Host "Attempting to use Azure CLI directly..." -ForegroundColor Yellow
                    foreach ($subnet in $subnetNames) {
                        Write-Host "Disabling NAT Gateway for subnet $subnet..." -ForegroundColor White
                        $result = az network vnet subnet update --resource-group $resourceGroup --vnet-name $vnetName --name $subnet --remove natGateway
                        
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "NAT Gateway disabled for subnet $subnet." -ForegroundColor Green
                        }
                        else {
                            Write-Host "Failed to disable NAT Gateway for subnet $subnet." -ForegroundColor Red
                        }
                    }
                }
                
                Pause
            }
            "3" {
                Write-Host "Checking NAT Gateway status..." -ForegroundColor Cyan
                $natGatewayName = "$($config.env)-$($config.loc)-natgw-$($config.project)"
                $status = az network nat gateway show --resource-group $resourceGroup --name $natGatewayName --query "provisioningState" -o tsv 2>$null
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "NAT Gateway Status: $status" -ForegroundColor Green
                    
                    # Get associated public IP addresses
                    $publicIps = az network nat gateway show --resource-group $resourceGroup --name $natGatewayName --query "publicIpAddresses[].id" -o tsv
                    if ($publicIps) {
                        Write-Host "Associated Public IPs:" -ForegroundColor Yellow
                        $publicIps -split "`n" | ForEach-Object {
                            $ipName = $_ -replace ".*/", ""
                            $ipAddress = az network public-ip show --ids $_ --query "ipAddress" -o tsv
                            Write-Host "- $ipName : $ipAddress" -ForegroundColor White
                        }
                    }
                    
                    # Get associated subnets
                    $vnetName = "$($config.env)-$($config.loc)-vnet-$($config.project)"
                    $subnetNames = @("$($config.env)-$($config.project)-snet-default", "$($config.env)-$($config.project)-snet-app")
                    
                    Write-Host "Checking subnet associations:" -ForegroundColor Yellow
                    foreach ($subnet in $subnetNames) {
                        $subnetNatGateway = az network vnet subnet show --resource-group $resourceGroup --vnet-name $vnetName --name $subnet --query "natGateway.id" -o tsv 2>$null
                        
                        if ($subnetNatGateway) {
                            Write-Host "- $subnet : Associated" -ForegroundColor Green
                        }
                        else {
                            Write-Host "- $subnet : Not associated" -ForegroundColor Red
                        }
                    }
                }
                else {
                    Write-Host "NAT Gateway not found or error retrieving status." -ForegroundColor Red
                }
                
                Pause
            }
            "0" {
                # Return to main menu
            }
            default {
                Write-Host "Invalid option. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($selection -ne "0")
}
