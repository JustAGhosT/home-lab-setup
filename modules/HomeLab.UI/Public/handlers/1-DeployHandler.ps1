<#
.SYNOPSIS
    Handles the deployment menu
.DESCRIPTION
    Processes user selections in the deployment menu and displays progress bars for deployment operations
.EXAMPLE
    Invoke-DeployMenu
.NOTES
    Author: Jurie Smit
    Date: March 8, 2025
#>
function Invoke-DeployMenu {
    [CmdletBinding()]
    param()
    
    $selection = 0
    do {
        Show-DeployMenu -ShowProgress
        $selection = Read-Host "Select an option"
        $config = Get-Configuration
        
        switch ($selection) {
            "1" {
                Write-ColorOutput "Starting full deployment..." -ForegroundColor Cyan
                
                # Create a progress task for the full deployment
                $task = Start-ProgressTask -Activity "Full Deployment" -TotalSteps 5 -ScriptBlock {
                    # Step 1: Resource Group
                    $syncHash.Status = "Creating Resource Group..."
                    $syncHash.CurrentStep = 1
                    
                    try {
                        # Call the actual deployment function
                        Deploy-Infrastructure
                        
                        # If the deployment is successful, return a success message
                        return "Full deployment completed successfully!"
                    }
                    catch {
                        return "Error during deployment: $_"
                    }
                }
                
                # Get the result and display it
                $result = $task.Complete()
                
                if ($result -like "Error*") {
                    Write-ColorOutput $result -ForegroundColor Red
                } else {
                    Write-ColorOutput $result -ForegroundColor Green
                }
                
                Pause
            }
            "2" {
                Write-ColorOutput "Deploying network only..." -ForegroundColor Cyan
                
                $task = Start-ProgressTask -Activity "Network Deployment" -TotalSteps 3 -ScriptBlock {
                    # Step 1: Resource Group
                    $syncHash.Status = "Creating/Verifying Resource Group..."
                    $syncHash.CurrentStep = 1
                    
                    # Step 2: Virtual Network
                    $syncHash.Status = "Deploying Virtual Network..."
                    $syncHash.CurrentStep = 2
                    
                    # Step 3: Subnets
                    $syncHash.Status = "Configuring Subnets..."
                    $syncHash.CurrentStep = 3
                    
                    try {
                        # Call the actual deployment function
                        Deploy-Infrastructure -ComponentsOnly "network"
                        
                        return "Network deployment completed successfully!"
                    }
                    catch {
                        return "Error deploying network: $_"
                    }
                }
                
                $result = $task.Complete()
                
                if ($result -like "Error*") {
                    Write-ColorOutput $result -ForegroundColor Red
                } else {
                    Write-ColorOutput $result -ForegroundColor Green
                }
                
                Pause
            }
            "3" {
                Write-ColorOutput "Deploying VPN Gateway only..." -ForegroundColor Cyan
                
                $task = Start-ProgressTask -Activity "VPN Gateway Deployment" -TotalSteps 4 -ScriptBlock {
                    # Step 1: Verify Prerequisites
                    $syncHash.Status = "Verifying prerequisites..."
                    $syncHash.CurrentStep = 1
                    
                    # Step 2: Public IP
                    $syncHash.Status = "Creating Public IP..."
                    $syncHash.CurrentStep = 2
                    
                    # Step 3: Gateway Subnet
                    $syncHash.Status = "Configuring Gateway Subnet..."
                    $syncHash.CurrentStep = 3
                    
                    # Step 4: VPN Gateway
                    $syncHash.Status = "Deploying VPN Gateway (this may take 30+ minutes)..."
                    $syncHash.CurrentStep = 4
                    
                    try {
                        # Call the actual deployment function
                        Deploy-Infrastructure -ComponentsOnly "vpngateway"
                        
                        return "VPN Gateway deployment initiated successfully! (Full provisioning may take 30+ minutes)"
                    }
                    catch {
                        return "Error deploying VPN Gateway: $_"
                    }
                }
                
                $result = $task.Complete()
                
                if ($result -like "Error*") {
                    Write-ColorOutput $result -ForegroundColor Red
                } else {
                    Write-ColorOutput $result -ForegroundColor Green
                }
                
                Pause
            }
            "4" {
                Write-ColorOutput "Deploying NAT Gateway only..." -ForegroundColor Cyan
                
                $task = Start-ProgressTask -Activity "NAT Gateway Deployment" -TotalSteps 3 -ScriptBlock {
                    # Step 1: Verify Prerequisites
                    $syncHash.Status = "Verifying prerequisites..."
                    $syncHash.CurrentStep = 1
                    
                    # Step 2: Public IP
                    $syncHash.Status = "Creating Public IP..."
                    $syncHash.CurrentStep = 2
                    
                    # Step 3: NAT Gateway
                    $syncHash.Status = "Deploying NAT Gateway..."
                    $syncHash.CurrentStep = 3
                    
                    try {
                        # Call the actual deployment function
                        Deploy-Infrastructure -ComponentsOnly "natgateway"
                        
                        return "NAT Gateway deployment completed successfully!"
                    }
                    catch {
                        return "Error deploying NAT Gateway: $_"
                    }
                }
                
                $result = $task.Complete()
                
                if ($result -like "Error*") {
                    Write-ColorOutput $result -ForegroundColor Red
                } else {
                    Write-ColorOutput $result -ForegroundColor Green
                }
                
                Pause
            }
            "5" {
                Write-ColorOutput "Checking deployment status..." -ForegroundColor Cyan
                
                $resourceGroup = "$($config.env)-$($config.loc)-rg-$($config.project)"
                
                $task = Start-ProgressTask -Activity "Checking Deployment Status" -TotalSteps 4 -ScriptBlock {
                    # Step 1: Resource Group
                    $syncHash.Status = "Checking Resource Group..."
                    $syncHash.CurrentStep = 1
                    
                    $status = az group show --name $resourceGroup --query "properties.provisioningState" -o tsv 2>$null
                    $rgStatus = if ($LASTEXITCODE -eq 0) { $status } else { "Not Found" }
                    
                    # Step 2: Virtual Network
                    $syncHash.Status = "Checking Virtual Network..."
                    $syncHash.CurrentStep = 2
                    
                    $vnetName = "$($config.env)-$($config.loc)-vnet-$($config.project)"
                    $vnetStatus = az network vnet show --resource-group $resourceGroup --name $vnetName --query "provisioningState" -o tsv 2>$null
                    $vnetStatus = if ($LASTEXITCODE -eq 0) { $vnetStatus } else { "Not Found" }
                    
                    # Step 3: VPN Gateway
                    $syncHash.Status = "Checking VPN Gateway..."
                    $syncHash.CurrentStep = 3
                    
                    $vpnGatewayName = "$($config.env)-$($config.loc)-vpng-$($config.project)"
                    $vpnStatus = az network vnet-gateway show --resource-group $resourceGroup --name $vpnGatewayName --query "provisioningState" -o tsv 2>$null
                    $vpnStatus = if ($LASTEXITCODE -eq 0) { $vpnStatus } else { "Not Found" }
                    
                    # Step 4: NAT Gateway
                    $syncHash.Status = "Checking NAT Gateway..."
                    $syncHash.CurrentStep = 4
                    
                    $natGatewayName = "$($config.env)-$($config.loc)-natgw-$($config.project)"
                    $natStatus = az network nat gateway show --resource-group $resourceGroup --name $natGatewayName --query "provisioningState" -o tsv 2>$null
                    $natStatus = if ($LASTEXITCODE -eq 0) { $natStatus } else { "Not Found" }
                    
                    # Return the status information
                    return @{
                        ResourceGroup = $rgStatus
                        VirtualNetwork = $vnetStatus
                        VPNGateway = $vpnStatus
                        NATGateway = $natStatus
                    }
                }
                
                $result = $task.Complete()
                
                # Display the results in a formatted way
                Write-ColorOutput "`nDeployment Status:" -ForegroundColor Cyan
                Write-ColorOutput "  Resource Group: $($result.ResourceGroup)" -ForegroundColor $(if ($result.ResourceGroup -eq "Succeeded") { "Green" } else { "Yellow" })
                Write-ColorOutput "  Virtual Network: $($result.VirtualNetwork)" -ForegroundColor $(if ($result.VirtualNetwork -eq "Succeeded") { "Green" } else { "Yellow" })
                Write-ColorOutput "  VPN Gateway: $($result.VPNGateway)" -ForegroundColor $(if ($result.VPNGateway -eq "Succeeded") { "Green" } else { "Yellow" })
                Write-ColorOutput "  NAT Gateway: $($result.NATGateway)" -ForegroundColor $(if ($result.NATGateway -eq "Succeeded") { "Green" } else { "Yellow" })
                
                Pause
            }
            "0" {
                # Return to main menu (do nothing here)
            }
            default {
                Write-ColorOutput "Invalid option. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($selection -ne "0")
}
