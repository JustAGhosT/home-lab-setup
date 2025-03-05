<#
.SYNOPSIS
    Handles the deployment menu
.DESCRIPTION
    Processes user selections in the deployment menu
.EXAMPLE
    Invoke-DeployMenu
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
                Deploy-Infrastructure -env $config.env -loc $config.loc -project $config.project -location $config.location -LogFile $config.LogFile
                Pause
            }
            "2" {
                Write-Host "Deploying network only..." -ForegroundColor Cyan
                Deploy-Infrastructure -env $config.env -loc $config.loc -project $config.project -location $config.location -LogFile $config.LogFile -ComponentsOnly "network"
                Pause
            }
            "3" {
                Write-Host "Deploying VPN Gateway only..." -ForegroundColor Cyan
                Deploy-Infrastructure -env $config.env -loc $config.loc -project $config.project -location $config.location -LogFile $config.LogFile -ComponentsOnly "vpngateway"
                Pause
            }
            "4" {
                Write-Host "Deploying NAT Gateway only..." -ForegroundColor Cyan
                Deploy-Infrastructure -env $config.env -loc $config.loc -project $config.project -location $config.location -LogFile $config.LogFile -ComponentsOnly "natgateway"
                Pause
            }
            "5" {
                Write-Host "Checking deployment status..." -ForegroundColor Cyan
                $resourceGroup = "$($config.env)-$($config.loc)-rg-$($config.project)"
                az group show --name $resourceGroup --query "properties.provisioningState" -o tsv
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
