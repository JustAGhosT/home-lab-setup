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
    Date: March 5, 2025
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
                NatGatewayEnableDisable -Enable -ResourceGroup $resourceGroup
                Pause
            }
            "2" {
                Write-Host "Disabling NAT Gateway..." -ForegroundColor Cyan
                NatGatewayEnableDisable -Disable -ResourceGroup $resourceGroup
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

Export-ModuleMember -Function Invoke-NatGatewayMenu
