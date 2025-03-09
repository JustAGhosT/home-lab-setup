<#
.SYNOPSIS
    Handles the deployment menu
.DESCRIPTION
    Processes user selections in the deployment menu and displays progress bars for deployment operations
.PARAMETER ShowProgress
    If specified, shows a progress bar while loading the menu.
.EXAMPLE
    Invoke-DeployMenu
.EXAMPLE
    Invoke-DeployMenu -ShowProgress
.NOTES
    Author: Jurie Smit
    Date: March 9, 2025
#>
function Invoke-DeployMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress
    )
    
    $exitMenu = $false
    
    do {
        # Get configuration for deployment operations
        $config = Get-Configuration -ErrorAction SilentlyContinue
        
        # If no configuration is found, notify the user and return to main menu
        if (-not $config) {
            Write-ColorOutput "Error: No configuration found. Please set up configuration first." -ForegroundColor Red
            Pause
            return
        }
        
        # Show the menu and get user selection
        $menuResult = Show-DeployMenu -ShowProgress:$ShowProgress
        
        # If user chose to exit, break the loop
        if ($menuResult.IsExit) {
            $exitMenu = $true
            continue
        }
        
        # Create a formatted string for deployment target
        $targetInfo = "[Target: $($config.env)-$($config.loc)-$($config.project)]"
        $resourceGroup = "$($config.env)-$($config.loc)-rg-$($config.project)"
        $location = $config.location
        
        # Process the user's choice
        switch ($menuResult.Choice) {
            "1" {
                Write-ColorOutput "Starting full deployment... $targetInfo" -ForegroundColor Cyan
                
                # Check if resource group exists
                $rgExists = az group exists --name $resourceGroup --output tsv 2>$null
                
                if ($rgExists -eq "true") {
                    Write-ColorOutput "Warning: Resource group '$resourceGroup' already exists." -ForegroundColor Yellow
                    $confirmation = Read-Host "Do you want to reset the resource group (delete and recreate)? (Y/N)"
                    
                    if ($confirmation -eq "Y" -or $confirmation -eq "y") {
                        # Reset the resource group
                        $resetResult = Reset-ResourceGroup -ResourceGroupName $resourceGroup -Location $location -Force
                        
                        if (-not $resetResult) {
                            Write-ColorOutput "Resource group reset failed or was cancelled. Deployment cancelled." -ForegroundColor Yellow
                            Pause
                            continue
                        }
                        
                        Write-ColorOutput "Resource group has been reset. Proceeding with deployment..." -ForegroundColor Green
                    }
                    else {
                        Write-ColorOutput "Proceeding with deployment to existing resource group..." -ForegroundColor Yellow
                        $confirmation = Read-Host "Skip confirmation prompts during deployment? (Y/N)"
                        $useForce = ($confirmation -eq "Y" -or $confirmation -eq "y")
                    }
                }
                
                $monitorConfirmation = Read-Host "Monitor deployment progress? (F)oreground, (B)ackground, or (N)one"
                $useMonitor = $monitorConfirmation -eq "F" -or $monitorConfirmation -eq "f"
                $useBackgroundMonitor = $monitorConfirmation -eq "B" -or $monitorConfirmation -eq "b"
                
                # Create a progress task for the full deployment
                $result = Start-ProgressTask -Activity "Full Deployment $targetInfo" -TotalSteps 5 -ScriptBlock {
                    # Step 1: Resource Group
                    $Global:syncHash.Status = "Creating/Verifying Resource Group..."
                    $Global:syncHash.CurrentStep = 1
                    
                    try {
                        # Call the actual deployment function with appropriate parameters
                        if ($useForce -and $useMonitor) {
                            Deploy-Infrastructure -Force -Monitor
                        } 
                        elseif ($useForce -and $useBackgroundMonitor) {
                            Deploy-Infrastructure -Force -BackgroundMonitor
                        }
                        elseif ($useForce) {
                            Deploy-Infrastructure -Force
                        }
                        elseif ($useMonitor) {
                            Deploy-Infrastructure -Monitor
                        }
                        elseif ($useBackgroundMonitor) {
                            Deploy-Infrastructure -BackgroundMonitor
                        }
                        else {
                            Deploy-Infrastructure
                        }
                        
                        # If background monitoring was started, show a message
                        if ($useBackgroundMonitor) {
                            return "Deployment initiated successfully! Background monitoring has been started."
                        }
                        
                        # If the deployment is successful, return a success message
                        return "Full deployment completed successfully!"
                    }
                    catch {
                        return "Error during deployment: $_"
                    }
                }
                
                if ($result -like "Error*") {
                    Write-ColorOutput $result -ForegroundColor Red
                } else {
                    Write-ColorOutput $result -ForegroundColor Green
                }
                
                Pause
            }
            "2" {
                Write-ColorOutput "Deploying network only... $targetInfo" -ForegroundColor Cyan
                
                # Check if resource group exists
                $rgExists = az group exists --name $resourceGroup --output tsv 2>$null
                
                if ($rgExists -ne "true") {
                    Write-ColorOutput "Resource group '$resourceGroup' does not exist. Creating it..." -ForegroundColor Yellow
                    az group create --name $resourceGroup --location $location | Out-Null
                }
                else {
                    # Check if network resources exist
                    $vnetName = "$($config.env)-$($config.loc)-vnet-$($config.project)"
                    $vnetExists = az network vnet show --resource-group $resourceGroup --name $vnetName --query "name" -o tsv 2>$null
                    
                    if ($vnetExists -or $LASTEXITCODE -eq 0) {
                        Write-ColorOutput "Warning: Virtual Network '$vnetName' already exists." -ForegroundColor Yellow
                        $confirmation = Read-Host "Do you want to delete and recreate the network resources? (Y/N)"
                        
                        if ($confirmation -eq "Y" -or $confirmation -eq "y") {
                            Write-ColorOutput "Deleting existing network resources..." -ForegroundColor Yellow
                            az network vnet delete --resource-group $resourceGroup --name $vnetName --yes 2>$null
                            Write-ColorOutput "Network resources deleted. Proceeding with deployment..." -ForegroundColor Green
                        }
                        else {
                            Write-ColorOutput "Proceeding with deployment to existing network..." -ForegroundColor Yellow
                            $confirmation = Read-Host "Skip confirmation prompts during deployment? (Y/N)"
                            $useForce = ($confirmation -eq "Y" -or $confirmation -eq "y")
                        }
                    }
                }
                
                $monitorConfirmation = Read-Host "Monitor deployment progress? (F)oreground, (B)ackground, or (N)one"
                $useMonitor = $monitorConfirmation -eq "F" -or $monitorConfirmation -eq "f"
                $useBackgroundMonitor = $monitorConfirmation -eq "B" -or $monitorConfirmation -eq "b"
                
                $result = Start-ProgressTask -Activity "Network Deployment $targetInfo" -TotalSteps 3 -ScriptBlock {
                    # Step 1: Resource Group
                    $Global:syncHash.Status = "Creating/Verifying Resource Group..."
                    $Global:syncHash.CurrentStep = 1
                    
                    # Step 2: Virtual Network
                    $Global:syncHash.Status = "Deploying Virtual Network..."
                    $Global:syncHash.CurrentStep = 2
                    
                    # Step 3: Subnets
                    $Global:syncHash.Status = "Configuring Subnets..."
                    $Global:syncHash.CurrentStep = 3
                    
                    try {
                        # Call the actual deployment function with appropriate parameters
                        if ($useForce -and $useMonitor) {
                            Deploy-Infrastructure -ComponentsOnly "network" -Force -Monitor
                        } 
                        elseif ($useForce -and $useBackgroundMonitor) {
                            Deploy-Infrastructure -ComponentsOnly "network" -Force -BackgroundMonitor
                        }
                        elseif ($useForce) {
                            Deploy-Infrastructure -ComponentsOnly "network" -Force
                        }
                        elseif ($useMonitor) {
                            Deploy-Infrastructure -ComponentsOnly "network" -Monitor
                        }
                        elseif ($useBackgroundMonitor) {
                            Deploy-Infrastructure -ComponentsOnly "network" -BackgroundMonitor
                        }
                        else {
                            Deploy-Infrastructure -ComponentsOnly "network"
                        }
                        
                        # If background monitoring was started, show a message
                        if ($useBackgroundMonitor) {
                            return "Deployment initiated successfully! Background monitoring has been started."
                        }
                        
                        return "Network deployment completed successfully!"
                    }
                    catch {
                        return "Error deploying network: $_"
                    }
                }
                
                if ($result -like "Error*") {
                    Write-ColorOutput $result -ForegroundColor Red
                } else {
                    Write-ColorOutput $result -ForegroundColor Green
                }
                
                Pause
            }
            "3" {
                Write-ColorOutput "Deploying VPN Gateway only... $targetInfo" -ForegroundColor Cyan
                
                # Display important warning about VPN Gateway deployment
                Write-ColorOutput "`n⚠️ IMPORTANT VPN GATEWAY INFORMATION ⚠️" -ForegroundColor Yellow
                Write-ColorOutput "- Deployment will take 30-45 minutes to complete" -ForegroundColor Yellow
                Write-ColorOutput "- VPN Gateway incurs hourly Azure charges (~$0.30-$1.20/hour depending on SKU)" -ForegroundColor Yellow
                Write-ColorOutput "- Gateway will continue to incur charges until explicitly deleted" -ForegroundColor Yellow
                Write-ColorOutput "- For testing purposes, consider deleting after use to minimize costs`n" -ForegroundColor Yellow
                
                $vpnConfirmation = Read-Host "Are you sure you want to proceed with VPN Gateway deployment? (Y/N)"
                if ($vpnConfirmation -ne "Y" -and $vpnConfirmation -ne "y") {
                    Write-ColorOutput "VPN Gateway deployment cancelled." -ForegroundColor Cyan
                    Pause
                    continue
                }
                
                # Check if resource group exists
                $rgExists = az group exists --name $resourceGroup --output tsv 2>$null
                
                if ($rgExists -ne "true") {
                    Write-ColorOutput "Resource group '$resourceGroup' does not exist. Creating it..." -ForegroundColor Yellow
                    az group create --name $resourceGroup --location $location | Out-Null
                }
                else {
                    # Check if VPN Gateway exists
                    $vpnGatewayName = "$($config.env)-$($config.loc)-vpng-$($config.project)"
                    $vpnExists = az network vnet-gateway show --resource-group $resourceGroup --name $vpnGatewayName --query "name" -o tsv 2>$null
                    
                    if ($vpnExists -or $LASTEXITCODE -eq 0) {
                        Write-ColorOutput "Warning: VPN Gateway '$vpnGatewayName' already exists." -ForegroundColor Yellow
                        $confirmation = Read-Host "Do you want to delete and recreate the VPN Gateway? (Y/N)"
                        
                        if ($confirmation -eq "Y" -or $confirmation -eq "y") {
                            Write-ColorOutput "Deleting existing VPN Gateway (this may take a few minutes)..." -ForegroundColor Yellow
                            az network vnet-gateway delete --resource-group $resourceGroup --name $vpnGatewayName --yes 2>$null
                            Write-ColorOutput "VPN Gateway deleted. Proceeding with deployment..." -ForegroundColor Green
                        }
                        else {
                            Write-ColorOutput "Proceeding with deployment to existing VPN Gateway..." -ForegroundColor Yellow
                            $confirmation = Read-Host "Skip confirmation prompts during deployment? (Y/N)"
                            $useForce = ($confirmation -eq "Y" -or $confirmation -eq "y")
                        }
                    }
                }
                
                # Check if network exists - VPN Gateway requires a virtual network
                $vnetName = "$($config.env)-$($config.loc)-vnet-$($config.project)"
                $vnetExists = az network vnet show --resource-group $resourceGroup --name $vnetName --query "name" -o tsv 2>$null
                
                if (-not $vnetExists -and $LASTEXITCODE -ne 0) {
                    Write-ColorOutput "Warning: Virtual Network '$vnetName' does not exist. VPN Gateway requires a virtual network." -ForegroundColor Yellow
                    $networkConfirmation = Read-Host "Would you like to deploy the network first? (Y/N)"
                    
                    if ($networkConfirmation -eq "Y" -or $networkConfirmation -eq "y") {
                        Write-ColorOutput "Deploying network resources first..." -ForegroundColor Cyan
                        
                        try {
                            Deploy-Infrastructure -ComponentsOnly "network" -Force
                            Write-ColorOutput "Network deployment completed. Proceeding with VPN Gateway deployment..." -ForegroundColor Green
                        }
                        catch {
                            Write-ColorOutput "Error deploying network: $_" -ForegroundColor Red
                            Write-ColorOutput "VPN Gateway deployment cancelled." -ForegroundColor Red
                            Pause
                            continue
                        }
                    }
                    else {
                        Write-ColorOutput "VPN Gateway requires a virtual network. Deployment cancelled." -ForegroundColor Red
                        Pause
                        continue
                    }
                }
                
                $monitorConfirmation = Read-Host "Monitor deployment progress? (F)oreground, (B)ackground, or (N)one"
                $useMonitor = $monitorConfirmation -eq "F" -or $monitorConfirmation -eq "f"
                $useBackgroundMonitor = $monitorConfirmation -eq "B" -or $monitorConfirmation -eq "b"
                
                $result = Start-ProgressTask -Activity "VPN Gateway Deployment $targetInfo" -TotalSteps 4 -ScriptBlock {
                    # Step 1: Verify Prerequisites
                    $Global:syncHash.Status = "Verifying prerequisites..."
                    $Global:syncHash.CurrentStep = 1
                    
                    # Step 2: Public IP
                    $Global:syncHash.Status = "Creating Public IP..."
                    $Global:syncHash.CurrentStep = 2
                    
                    # Step 3: Gateway Subnet
                    $Global:syncHash.Status = "Configuring Gateway Subnet..."
                    $Global:syncHash.CurrentStep = 3
                    
                    # Step 4: VPN Gateway
                    $Global:syncHash.Status = "Deploying VPN Gateway (this may take 30+ minutes)..."
                    $Global:syncHash.CurrentStep = 4
                    
                    try {
                        # Call the actual deployment function with appropriate parameters
                        if ($useForce -and $useMonitor) {
                            Deploy-Infrastructure -ComponentsOnly "vpngateway" -Force -Monitor
                        } 
                        elseif ($useForce -and $useBackgroundMonitor) {
                            Deploy-Infrastructure -ComponentsOnly "vpngateway" -Force -BackgroundMonitor
                        }
                        elseif ($useForce) {
                            Deploy-Infrastructure -ComponentsOnly "vpngateway" -Force
                        }
                        elseif ($useMonitor) {
                            Deploy-Infrastructure -ComponentsOnly "vpngateway" -Monitor
                        }
                        elseif ($useBackgroundMonitor) {
                            Deploy-Infrastructure -ComponentsOnly "vpngateway" -BackgroundMonitor
                        }
                        else {
                            Deploy-Infrastructure -ComponentsOnly "vpngateway"
                        }
                        
                        # If background monitoring was started, show a message
                        if ($useBackgroundMonitor) {
                            return "Deployment initiated successfully! Background monitoring has been started."
                        }
                        
                        return "VPN Gateway deployment initiated successfully! (Full provisioning may take 30+ minutes)"
                    }
                    catch {
                        return "Error deploying VPN Gateway: $_"
                    }
                }
                
                if ($result -like "Error*") {
                    Write-ColorOutput $result -ForegroundColor Red
                } else {
                    Write-ColorOutput $result -ForegroundColor Green
                    Write-ColorOutput "`nIMPORTANT: The VPN Gateway will continue to incur charges until explicitly deleted." -ForegroundColor Yellow
                    Write-ColorOutput "Use option 5 to check deployment status. When finished testing, consider deleting the VPN Gateway." -ForegroundColor Yellow
                }
                
                Pause
            }            "4" {
                Write-ColorOutput "Deploying NAT Gateway only... $targetInfo" -ForegroundColor Cyan
                
                # Check if resource group exists
                $rgExists = az group exists --name $resourceGroup --output tsv 2>$null
                
                if ($rgExists -ne "true") {
                    Write-ColorOutput "Resource group '$resourceGroup' does not exist. Creating it..." -ForegroundColor Yellow
                    az group create --name $resourceGroup --location $location | Out-Null
                }
                else {
                    # Check if NAT Gateway exists
                    $natGatewayName = "$($config.env)-$($config.loc)-natgw-$($config.project)"
                    $natExists = az network nat gateway show --resource-group $resourceGroup --name $natGatewayName --query "name" -o tsv 2>$null
                    
                    if ($natExists -or $LASTEXITCODE -eq 0) {
                        Write-ColorOutput "Warning: NAT Gateway '$natGatewayName' already exists." -ForegroundColor Yellow
                        $confirmation = Read-Host "Do you want to delete and recreate the NAT Gateway? (Y/N)"
                        
                        if ($confirmation -eq "Y" -or $confirmation -eq "y") {
                            Write-ColorOutput "Deleting existing NAT Gateway..." -ForegroundColor Yellow
                            az network nat gateway delete --resource-group $resourceGroup --name $natGatewayName --yes 2>$null
                            Write-ColorOutput "NAT Gateway deleted. Proceeding with deployment..." -ForegroundColor Green
                        }
                        else {
                            Write-ColorOutput "Proceeding with deployment to existing NAT Gateway..." -ForegroundColor Yellow
                            $confirmation = Read-Host "Skip confirmation prompts during deployment? (Y/N)"
                            $useForce = ($confirmation -eq "Y" -or $confirmation -eq "y")
                        }
                    }
                }
                
                $monitorConfirmation = Read-Host "Monitor deployment progress? (F)oreground, (B)ackground, or (N)one"
                $useMonitor = $monitorConfirmation -eq "F" -or $monitorConfirmation -eq "f"
                $useBackgroundMonitor = $monitorConfirmation -eq "B" -or $monitorConfirmation -eq "b"
                
                $result = Start-ProgressTask -Activity "NAT Gateway Deployment $targetInfo" -TotalSteps 3 -ScriptBlock {
                    # Step 1: Verify Prerequisites
                    $Global:syncHash.Status = "Verifying prerequisites..."
                    $Global:syncHash.CurrentStep = 1
                    
                    # Step 2: Public IP
                    $Global:syncHash.Status = "Creating Public IP..."
                    $Global:syncHash.CurrentStep = 2
                    
                    # Step 3: NAT Gateway
                    $Global:syncHash.Status = "Deploying NAT Gateway..."
                    $Global:syncHash.CurrentStep = 3
                    
                    try {
                        # Call the actual deployment function with appropriate parameters
                        if ($useForce -and $useMonitor) {
                            Deploy-Infrastructure -ComponentsOnly "natgateway" -Force -Monitor
                        } 
                        elseif ($useForce -and $useBackgroundMonitor) {
                            Deploy-Infrastructure -ComponentsOnly "natgateway" -Force -BackgroundMonitor
                        }
                        elseif ($useForce) {
                            Deploy-Infrastructure -ComponentsOnly "natgateway" -Force
                        }
                        elseif ($useMonitor) {
                            Deploy-Infrastructure -ComponentsOnly "natgateway" -Monitor
                        }
                        elseif ($useBackgroundMonitor) {
                            Deploy-Infrastructure -ComponentsOnly "natgateway" -BackgroundMonitor
                        }
                        else {
                            Deploy-Infrastructure -ComponentsOnly "natgateway"
                        }
                        
                        # If background monitoring was started, show a message
                        if ($useBackgroundMonitor) {
                            return "Deployment initiated successfully! Background monitoring has been started."
                        }
                        
                        return "NAT Gateway deployment completed successfully!"
                    }
                    catch {
                        return "Error deploying NAT Gateway: $_"
                    }
                }
                
                if ($result -like "Error*") {
                    Write-ColorOutput $result -ForegroundColor Red
                } else {
                    Write-ColorOutput $result -ForegroundColor Green
                }
                
                Pause
            }
            "5" {
                Write-ColorOutput "Checking deployment status... $targetInfo" -ForegroundColor Cyan
                
                $result = Start-ProgressTask -Activity "Checking Deployment Status $targetInfo" -TotalSteps 4 -ScriptBlock {
                    # Step 1: Resource Group
                    $Global:syncHash.Status = "Checking Resource Group..."
                    $Global:syncHash.CurrentStep = 1
                    
                    $status = az group show --name $resourceGroup --query "properties.provisioningState" -o tsv 2>$null
                    $rgStatus = if ($LASTEXITCODE -eq 0) { $status } else { "Not Found" }
                    
                    # Step 2: Virtual Network
                    $Global:syncHash.Status = "Checking Virtual Network..."
                    $Global:syncHash.CurrentStep = 2
                    
                    $vnetName = "$($config.env)-$($config.loc)-vnet-$($config.project)"
                    $vnetStatus = az network vnet show --resource-group $resourceGroup --name $vnetName --query "provisioningState" -o tsv 2>$null
                    $vnetStatus = if ($LASTEXITCODE -eq 0) { $vnetStatus } else { "Not Found" }
                    
                    # Step 3: VPN Gateway
                    $Global:syncHash.Status = "Checking VPN Gateway..."
                    $Global:syncHash.CurrentStep = 3
                    
                    $vpnGatewayName = "$($config.env)-$($config.loc)-vpng-$($config.project)"
                    $vpnStatus = az network vnet-gateway show --resource-group $resourceGroup --name $vpnGatewayName --query "provisioningState" -o tsv 2>$null
                    $vpnStatus = if ($LASTEXITCODE -eq 0) { $vpnStatus } else { "Not Found" }
                    
                    # Step 4: NAT Gateway
                    $Global:syncHash.Status = "Checking NAT Gateway..."
                    $Global:syncHash.CurrentStep = 4
                    
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
                
                # Display the results in a formatted way
                Write-ColorOutput "`nDeployment Status for $($targetInfo):" -ForegroundColor Cyan
                Write-ColorOutput "  Resource Group: $($result.ResourceGroup)" -ForegroundColor $(if ($result.ResourceGroup -eq "Succeeded") { "Green" } else { "Yellow" })
                Write-ColorOutput "  Virtual Network: $($result.VirtualNetwork)" -ForegroundColor $(if ($result.VirtualNetwork -eq "Succeeded") { "Green" } else { "Yellow" })
                Write-ColorOutput "  VPN Gateway: $($result.VPNGateway)" -ForegroundColor $(if ($result.VPNGateway -eq "Succeeded") { "Green" } else { "Yellow" })
                Write-ColorOutput "  NAT Gateway: $($result.NATGateway)" -ForegroundColor $(if ($result.NATGateway -eq "Succeeded") { "Green" } else { "Yellow" })
                
                Pause
            }
            "7" {
                Write-ColorOutput "Background Monitoring Status... $targetInfo" -ForegroundColor Cyan
                
                # Display all background monitoring jobs
                Show-BackgroundMonitoringStatus
                
                # Option to clean up completed jobs
                $cleanupConfirmation = Read-Host "`nWould you like to clean up completed monitoring jobs? (Y/N)"
                if ($cleanupConfirmation -eq "Y" -or $cleanupConfirmation -eq "y") {
                    $completedJobs = Get-Job | Where-Object { $_.Name -like "Monitor_*" -and $_.State -eq "Completed" }
                    if ($completedJobs) {
                        $completedJobs | Remove-Job
                        Write-ColorOutput "Completed monitoring jobs have been removed." -ForegroundColor Green
                    } else {
                        Write-ColorOutput "No completed monitoring jobs to clean up." -ForegroundColor Yellow
                    }
                }
                
                Pause
            }
            default {
                Write-ColorOutput "Invalid option. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
        
        # Only show progress on first display
        $ShowProgress = $false
        
    } while (-not $exitMenu)
}