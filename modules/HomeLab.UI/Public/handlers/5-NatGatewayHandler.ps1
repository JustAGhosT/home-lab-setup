<#
.SYNOPSIS
    NAT Gateway Menu Handler for HomeLab Setup
.DESCRIPTION
    Processes user selections in the NAT gateway menu using the new modular structure.
    Options include enabling/disabling the NAT Gateway and checking its status.
.PARAMETER ShowProgress
    If specified, shows a progress bar while loading the menu and performing operations.
.EXAMPLE
    Invoke-NatGatewayMenu
.EXAMPLE
    Invoke-NatGatewayMenu -ShowProgress
.NOTES
    Author: Jurie Smit
    Date: March 8, 2025
#>
function Invoke-NatGatewayMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress
    )
    
    # Check if required functions exist
    $requiredFunctions = @(
        "Show-NatGatewayMenu",
        "Get-Configuration",
        "Pause"
    )
    
    foreach ($function in $requiredFunctions) {
        if (-not (Get-Command -Name $function -ErrorAction SilentlyContinue)) {
            Write-Error "Required function '$function' not found. Make sure all required modules are imported."
            return
        }
    }
    
    # Check if logging is available
    $canLog = Get-Command -Name "Write-Log" -ErrorAction SilentlyContinue
    
    if ($canLog) {
        Write-Log -Message "Entering NAT Gateway Menu" -Level INFO
    }
    
    $selection = 0
    do {
        try {
            Show-NatGatewayMenu -ShowProgress:$ShowProgress
        }
        catch {
            Write-Host "Error displaying NAT Gateway Menu: $_" -ForegroundColor Red
            if ($canLog) { Write-Log -Message "Error displaying NAT Gateway Menu: $_" -Level ERROR }
            break
        }
        
        $selection = Read-Host "Select an option"
        $config = Get-Configuration
        $resourceGroup = "$($config.env)-$($config.loc)-rg-$($config.project)"
        
        switch ($selection) {
            "1" {
                Write-Host "Enabling NAT Gateway..." -ForegroundColor Cyan
                if ($canLog) { Write-Log -Message "User selected: Enable NAT Gateway" -Level INFO }
                
                $natGatewayName = "$($config.env)-$($config.loc)-natgw-$($config.project)"
                $vnetName = "$($config.env)-$($config.loc)-vnet-$($config.project)"
                $subnetNames = @("$($config.env)-$($config.project)-snet-default", "$($config.env)-$($config.project)-snet-app")
                
                if ($ShowProgress) {
                    # Create a progress task for enabling NAT Gateway
                    $task = Start-ProgressTask -Activity "Enabling NAT Gateway" -TotalSteps 4 -ScriptBlock {
                        # Step 1: Checking for required functions
                        $syncHash.Status = "Checking for required functions..."
                        $syncHash.CurrentStep = 1
                        
                        $useFunction = Get-Command NatGatewayEnableDisable -ErrorAction SilentlyContinue
                        
                        # Step 2: Validating resources
                        $syncHash.Status = "Validating resources..."
                        $syncHash.CurrentStep = 2
                        
                        # Check if NAT Gateway exists
                        $natGwExists = az network nat gateway show --resource-group $resourceGroup --name $natGatewayName --query "name" -o tsv 2>$null
                        
                        if (-not $natGwExists) {
                            return @{
                                Success = $false,
                                ErrorMessage = "NAT Gateway '$natGatewayName' does not exist in resource group '$resourceGroup'."
                            }
                        }
                        
                        # Step 3: Preparing subnet configurations
                        $syncHash.Status = "Preparing subnet configurations..."
                        $syncHash.CurrentStep = 3
                        
                        # Step 4: Applying NAT Gateway to subnets
                        $syncHash.Status = "Applying NAT Gateway to subnets..."
                        $syncHash.CurrentStep = 4
                        
                        if ($useFunction) {
                            try {
                                NatGatewayEnableDisable -Enable -ResourceGroup $resourceGroup
                                return @{
                                    Success = $true
                                    UsedFunction = $true
                                }
                            }
                            catch {
                                return @{
                                    Success = $false
                                    ErrorMessage = "Error enabling NAT Gateway: $_"
                                    UsedFunction = $true
                                }
                            }
                        }
                        else {
                            $results = @()
                            
                            foreach ($subnet in $subnetNames) {
                                try {
                                    $result = az network vnet subnet update --resource-group $resourceGroup --vnet-name $vnetName --name $subnet --nat-gateway $natGatewayName 2>&1
                                    
                                    $results += @{
                                        SubnetName = $subnet
                                        Success = ($LASTEXITCODE -eq 0)
                                        Error = if ($LASTEXITCODE -ne 0) { $result } else { $null }
                                    }
                                }
                                catch {
                                    $results += @{
                                        SubnetName = $subnet
                                        Success = $false
                                        Error = $_.Exception.Message
                                    }
                                }
                            }
                            
                            return @{
                                Success = ($results | Where-Object { -not $_.Success }).Count -eq 0
                                UsedFunction = $false
                                Results = $results
                            }
                        }
                    }
                    
                    $result = $task.Complete()
                    
                    if ($result.Success) {
                        if ($result.UsedFunction) {
                            Write-Host "NAT Gateway enabled successfully using NatGatewayEnableDisable function." -ForegroundColor Green
                            if ($canLog) { Write-Log -Message "NAT Gateway enabled successfully using NatGatewayEnableDisable function" -Level INFO }
                        }
                        else {
                            Write-Host "NAT Gateway enabled successfully for all subnets." -ForegroundColor Green
                            if ($canLog) { Write-Log -Message "NAT Gateway enabled successfully for all subnets" -Level INFO }
                            
                            foreach ($subnetResult in $result.Results) {
                                Write-Host "- Subnet $($subnetResult.SubnetName): Enabled" -ForegroundColor Green
                                if ($canLog) { Write-Log -Message "NAT Gateway enabled for subnet $($subnetResult.SubnetName)" -Level INFO }
                            }
                        }
                    }
                    else {
                        if ($result.UsedFunction) {
                            Write-Host "Function NatGatewayEnableDisable not found. Make sure the required module is imported." -ForegroundColor Red
                            if ($canLog) { Write-Log -Message "Function NatGatewayEnableDisable not found" -Level ERROR }
                            Write-Host $result.ErrorMessage -ForegroundColor Red
                            if ($canLog) { Write-Log -Message $result.ErrorMessage -Level ERROR }
                        }
                        else {
                            if ($result.ErrorMessage) {
                                Write-Host $result.ErrorMessage -ForegroundColor Red
                                if ($canLog) { Write-Log -Message $result.ErrorMessage -Level ERROR }
                            }
                            else {
                                Write-Host "Failed to enable NAT Gateway for some subnets:" -ForegroundColor Red
                                if ($canLog) { Write-Log -Message "Failed to enable NAT Gateway for some subnets" -Level ERROR }
                                
                                foreach ($subnetResult in $result.Results) {
                                    if ($subnetResult.Success) {
                                        Write-Host "- Subnet $($subnetResult.SubnetName): Enabled" -ForegroundColor Green
                                        if ($canLog) { Write-Log -Message "NAT Gateway enabled for subnet $($subnetResult.SubnetName)" -Level INFO }
                                    }
                                    else {
                                        Write-Host "- Subnet $($subnetResult.SubnetName): Failed" -ForegroundColor Red
                                        Write-Host "  Error: $($subnetResult.Error)" -ForegroundColor Red
                                        if ($canLog) { Write-Log -Message "Failed to enable NAT Gateway for subnet $($subnetResult.SubnetName): $($subnetResult.Error)" -Level ERROR }
                                    }
                                }
                            }
                        }
                    }
                }
                else {
                    # Original implementation without progress bar
                    # Assuming NatGatewayEnableDisable is defined in another module
                    if (Get-Command NatGatewayEnableDisable -ErrorAction SilentlyContinue) {
                        NatGatewayEnableDisable -Enable -ResourceGroup $resourceGroup
                        if ($canLog) { Write-Log -Message "Called NatGatewayEnableDisable -Enable -ResourceGroup $resourceGroup" -Level INFO }
                    }
                    else {
                        Write-Host "Function NatGatewayEnableDisable not found. Make sure the required module is imported." -ForegroundColor Red
                        if ($canLog) { Write-Log -Message "Function NatGatewayEnableDisable not found" -Level ERROR }
                        
                        # Fallback to direct Azure CLI command
                        Write-Host "Attempting to use Azure CLI directly..." -ForegroundColor Yellow
                        if ($canLog) { Write-Log -Message "Attempting to use Azure CLI directly" -Level INFO }
                        
                        foreach ($subnet in $subnetNames) {
                            Write-Host "Enabling NAT Gateway for subnet $subnet..." -ForegroundColor White
                            if ($canLog) { Write-Log -Message "Enabling NAT Gateway for subnet $subnet" -Level INFO }
                            
                            $result = az network vnet subnet update --resource-group $resourceGroup --vnet-name $vnetName --name $subnet --nat-gateway $natGatewayName
                            
                            if ($LASTEXITCODE -eq 0) {
                                Write-Host "NAT Gateway enabled for subnet $subnet." -ForegroundColor Green
                                if ($canLog) { Write-Log -Message "NAT Gateway enabled for subnet $subnet" -Level INFO }
                            }
                            else {
                                Write-Host "Failed to enable NAT Gateway for subnet $subnet." -ForegroundColor Red
                                if ($canLog) { Write-Log -Message "Failed to enable NAT Gateway for subnet $subnet" -Level ERROR }
                            }
                        }
                    }
                }
                
                Pause
            }
            "2" {
                Write-Host "Disabling NAT Gateway..." -ForegroundColor Cyan
                if ($canLog) { Write-Log -Message "User selected: Disable NAT Gateway" -Level INFO }
                
                $vnetName = "$($config.env)-$($config.loc)-vnet-$($config.project)"
                $subnetNames = @("$($config.env)-$($config.project)-snet-default", "$($config.env)-$($config.project)-snet-app")
                
                if ($ShowProgress) {
                    # Create a progress task for disabling NAT Gateway
                    $task = Start-ProgressTask -Activity "Disabling NAT Gateway" -TotalSteps 3 -ScriptBlock {
                        # Step 1: Checking for required functions
                        $syncHash.Status = "Checking for required functions..."
                        $syncHash.CurrentStep = 1
                        
                        $useFunction = Get-Command NatGatewayEnableDisable -ErrorAction SilentlyContinue
                        
                        # Step 2: Validating resources
                        $syncHash.Status = "Validating resources..."
                        $syncHash.CurrentStep = 2
                        
                        # Step 3: Removing NAT Gateway from subnets
                        $syncHash.Status = "Removing NAT Gateway from subnets..."
                        $syncHash.CurrentStep = 3
                        
                        if ($useFunction) {
                            try {
                                NatGatewayEnableDisable -Disable -ResourceGroup $resourceGroup
                                return @{
                                    Success = $true
                                    UsedFunction = $true
                                }
                            }
                            catch {
                                return @{
                                    Success = $false
                                    ErrorMessage = "Error disabling NAT Gateway: $_"
                                    UsedFunction = $true
                                }
                            }
                        }
                        else {
                            $results = @()
                            
                            foreach ($subnet in $subnetNames) {
                                try {
                                    $result = az network vnet subnet update --resource-group $resourceGroup --vnet-name $vnetName --name $subnet --remove natGateway 2>&1
                                    
                                    $results += @{
                                        SubnetName = $subnet
                                        Success = ($LASTEXITCODE -eq 0)
                                        Error = if ($LASTEXITCODE -ne 0) { $result } else { $null }
                                    }
                                }
                                catch {
                                    $results += @{
                                        SubnetName = $subnet
                                        Success = $false
                                        Error = $_.Exception.Message
                                    }
                                }
                            }
                            
                            return @{
                                Success = ($results | Where-Object { -not $_.Success }).Count -eq 0
                                UsedFunction = $false
                                Results = $results
                            }
                        }
                    }
                    
                    $result = $task.Complete()
                    
                    if ($result.Success) {
                        if ($result.UsedFunction) {
                            Write-Host "NAT Gateway disabled successfully using NatGatewayEnableDisable function." -ForegroundColor Green
                            if ($canLog) { Write-Log -Message "NAT Gateway disabled successfully using NatGatewayEnableDisable function" -Level INFO }
                        }
                        else {
                            Write-Host "NAT Gateway disabled successfully for all subnets." -ForegroundColor Green
                            if ($canLog) { Write-Log -Message "NAT Gateway disabled successfully for all subnets" -Level INFO }
                            
                            foreach ($subnetResult in $result.Results) {
                                Write-Host "- Subnet $($subnetResult.SubnetName): Disabled" -ForegroundColor Green
                                if ($canLog) { Write-Log -Message "NAT Gateway disabled for subnet $($subnetResult.SubnetName)" -Level INFO }
                            }
                        }
                    }
                    else {
                        if ($result.UsedFunction) {
                            Write-Host "Function NatGatewayEnableDisable not found. Make sure the required module is imported." -ForegroundColor Red
                            if ($canLog) { Write-Log -Message "Function NatGatewayEnableDisable not found" -Level ERROR }
                            Write-Host $result.ErrorMessage -ForegroundColor Red
                            if ($canLog) { Write-Log -Message $result.ErrorMessage -Level ERROR }
                        }
                        else {
                            Write-Host "Failed to disable NAT Gateway for some subnets:" -ForegroundColor Red
                            if ($canLog) { Write-Log -Message "Failed to disable NAT Gateway for some subnets" -Level ERROR }
                            
                            foreach ($subnetResult in $result.Results) {
                                if ($subnetResult.Success) {
                                    Write-Host "- Subnet $($subnetResult.SubnetName): Disabled" -ForegroundColor Green
                                    if ($canLog) { Write-Log -Message "NAT Gateway disabled for subnet $($subnetResult.SubnetName)" -Level INFO }
                                }
                                else {
                                    Write-Host "- Subnet $($subnetResult.SubnetName): Failed" -ForegroundColor Red
                                    Write-Host "  Error: $($subnetResult.Error)" -ForegroundColor Red
                                    if ($canLog) { Write-Log -Message "Failed to disable NAT Gateway for subnet $($subnetResult.SubnetName): $($subnetResult.Error)" -Level ERROR }
                                }
                            }
                        }
                    }
                }
                else {
                    # Original implementation without progress bar
                    # Assuming NatGatewayEnableDisable is defined in another module
                    if (Get-Command NatGatewayEnableDisable -ErrorAction SilentlyContinue) {
                        NatGatewayEnableDisable -Disable -ResourceGroup $resourceGroup
                        if ($canLog) { Write-Log -Message "Called NatGatewayEnableDisable -Disable -ResourceGroup $resourceGroup" -Level INFO }
                    }
                    else {
                        Write-Host "Function NatGatewayEnableDisable not found. Make sure the required module is imported." -ForegroundColor Red
                        if ($canLog) { Write-Log -Message "Function NatGatewayEnableDisable not found" -Level ERROR }
                        
                        # Fallback to direct Azure CLI command
                        Write-Host "Attempting to use Azure CLI directly..." -ForegroundColor Yellow
                        if ($canLog) { Write-Log -Message "Attempting to use Azure CLI directly" -Level INFO }
                        
                        foreach ($subnet in $subnetNames) {
                            Write-Host "Disabling NAT Gateway for subnet $subnet..." -ForegroundColor White
                            if ($canLog) { Write-Log -Message "Disabling NAT Gateway for subnet $subnet" -Level INFO }
                            
                            $result = az network vnet subnet update --resource-group $resourceGroup --vnet-name $vnetName --name $subnet --remove natGateway
                            
                            if ($LASTEXITCODE -eq 0) {
                                Write-Host "NAT Gateway disabled for subnet $subnet." -ForegroundColor Green
                                if ($canLog) { Write-Log -Message "NAT Gateway disabled for subnet $subnet" -Level INFO }
                            }
                            else {
                                Write-Host "Failed to disable NAT Gateway for subnet $subnet." -ForegroundColor Red
                                if ($canLog) { Write-Log -Message "Failed to disable NAT Gateway for subnet $subnet" -Level ERROR }
                            }
                        }
                    }
                }
                
                Pause
            }
            "3" {
                Write-Host "Checking NAT Gateway status..." -ForegroundColor Cyan
                if ($canLog) { Write-Log -Message "User selected: Check NAT Gateway status" -Level INFO }
                
                $natGatewayName = "$($config.env)-$($config.loc)-natgw-$($config.project)"
                $vnetName = "$($config.env)-$($config.loc)-vnet-$($config.project)"
                $subnetNames = @("$($config.env)-$($config.project)-snet-default", "$($config.env)-$($config.project)-snet-app")
                
                if ($ShowProgress) {
                    # Create a progress task for checking NAT Gateway status
                    $task = Start-ProgressTask -Activity "Checking NAT Gateway Status" -TotalSteps 4 -ScriptBlock {
                        # Step 1: Retrieving NAT Gateway status
                        $syncHash.Status = "Retrieving NAT Gateway status..."
                        $syncHash.CurrentStep = 1
                        
                        $status = az network nat gateway show --resource-group $resourceGroup --name $natGatewayName --query "provisioningState" -o tsv 2>$null
                        $natGatewayExists = ($LASTEXITCODE -eq 0)
                        
                        if (-not $natGatewayExists) {
                            return @{
                                Success = $false,
                                ErrorMessage = "NAT Gateway not found or error retrieving status."
                            }
                        }
                        
                        # Step 2: Retrieving public IP information
                        $syncHash.Status = "Retrieving public IP information..."
                        $syncHash.CurrentStep = 2
                        
                        $publicIpsData = @()
                        $publicIps = az network nat gateway show --resource-group $resourceGroup --name $natGatewayName --query "publicIpAddresses[].id" -o tsv
                        
                        if ($publicIps) {
                            foreach ($ip in ($publicIps -split "`n")) {
                                $ipName = $ip -replace ".*/", ""
                                $ipAddress = az network public-ip show --ids $ip --query "ipAddress" -o tsv
                                
                                $publicIpsData += @{
                                    Name = $ipName
                                    Address = $ipAddress
                                }
                            }
                        }
                        
                        # Step 3: Checking subnet associations
                        $syncHash.Status = "Checking subnet associations..."
                        $syncHash.CurrentStep = 3
                        
                        $subnetData = @()
                        
                        foreach ($subnet in $subnetNames) {
                            $subnetNatGateway = az network vnet subnet show --resource-group $resourceGroup --vnet-name $vnetName --name $subnet --query "natGateway.id" -o tsv 2>$null
                            
                            $subnetData += @{
                                Name = $subnet
                                Associated = [bool]$subnetNatGateway
                            }
                        }
                        
                        # Step 4: Gathering additional details
                        $syncHash.Status = "Gathering additional details..."
                        $syncHash.CurrentStep = 4
                        
                        $idleTimeout = az network nat gateway show --resource-group $resourceGroup --name $natGatewayName --query "idleTimeoutInMinutes" -o tsv
                        $skuName = az network nat gateway show --resource-group $resourceGroup --name $natGatewayName --query "sku.name" -o tsv
                        
                        return @{
                            Success = $true
                            Status = $status
                            PublicIps = $publicIpsData
                            Subnets = $subnetData
                            IdleTimeout = $idleTimeout
                            SkuName = $skuName
                        }
                    }
                    
                    $result = $task.Complete()
                    
                    if ($result.Success) {
                        Write-Host "NAT Gateway Status: $($result.Status)" -ForegroundColor Green
                        if ($canLog) { Write-Log -Message "NAT Gateway Status: $($result.Status)" -Level INFO }
                        
                        Write-Host "SKU: $($result.SkuName)" -ForegroundColor White
                        Write-Host "Idle Timeout: $($result.IdleTimeout) minutes" -ForegroundColor White
                        
                        if ($result.PublicIps -and $result.PublicIps.Count -gt 0) {
                            Write-Host "Associated Public IPs:" -ForegroundColor Yellow
                            foreach ($ip in $result.PublicIps) {
                                Write-Host "- $($ip.Name) : $($ip.Address)" -ForegroundColor White
                            }
                        }
                        else {
                            Write-Host "No public IPs associated with this NAT Gateway." -ForegroundColor Yellow
                        }
                        
                        Write-Host "Subnet Associations:" -ForegroundColor Yellow
                        foreach ($subnet in $result.Subnets) {
                            if ($subnet.Associated) {
                                Write-Host "- $($subnet.Name) : Associated" -ForegroundColor Green
                            }
                            else {
                                Write-Host "- $($subnet.Name) : Not associated" -ForegroundColor Red
                            }
                        }
                    }
                    else {
                        Write-Host $result.ErrorMessage -ForegroundColor Red
                        if ($canLog) { Write-Log -Message $result.ErrorMessage -Level ERROR }
                    }
                }
                else {
                    # Original implementation without progress bar
                    $status = az network nat gateway show --resource-group $resourceGroup --name $natGatewayName --query "provisioningState" -o tsv 2>$null
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "NAT Gateway Status: $status" -ForegroundColor Green
                        if ($canLog) { Write-Log -Message "NAT Gateway Status: $status" -Level INFO }
                        
                        # Get associated public IP addresses
                        $publicIps = az network nat gateway show --resource-group $resourceGroup --name $natGatewayName --query "publicIpAddresses[].id" -o tsv
                        if ($publicIps) {
                            Write-Host "Associated Public IPs:" -ForegroundColor Yellow
                            $publicIps -split "`n" | ForEach-Object {
                                $ipName = $_ -replace ".*/", ""
                                $ipAddress = az network public-ip show --ids $_ --query "ipAddress" -o tsv
                                Write-Host "- $ipName : $ipAddress" -ForegroundColor White
                                if ($canLog) { Write-Log -Message "Public IP: $ipName : $ipAddress" -Level INFO }
                            }
                        }
                        
                        # Get associated subnets
                        Write-Host "Checking subnet associations:" -ForegroundColor Yellow
                        foreach ($subnet in $subnetNames) {
                            $subnetNatGateway = az network vnet subnet show --resource-group $resourceGroup --vnet-name $vnetName --name $subnet --query "natGateway.id" -o tsv 2>$null
                            
                            if ($subnetNatGateway) {
                                Write-Host "- $subnet : Associated" -ForegroundColor Green
                                if ($canLog) { Write-Log -Message "Subnet $subnet : Associated with NAT Gateway" -Level INFO }
                            }
                            else {
                                Write-Host "- $subnet : Not associated" -ForegroundColor Red
                                if ($canLog) { Write-Log -Message "Subnet $subnet : Not associated with NAT Gateway" -Level INFO }
                            }
                        }
                    }
                    else {
                        Write-Host "NAT Gateway not found or error retrieving status." -ForegroundColor Red
                        if ($canLog) { Write-Log -Message "NAT Gateway not found or error retrieving status" -Level ERROR }
                    }
                }
                
                Pause
            }
            "0" {
                # Return to main menu
                if ($canLog) { Write-Log -Message "User exited NAT Gateway Menu" -Level INFO }
            }
            default {
                Write-Host "Invalid option. Please try again." -ForegroundColor Red
                if ($canLog) { Write-Log -Message "User selected invalid option: $selection" -Level WARN }
                Start-Sleep -Seconds 2
            }
        }
    } while ($selection -ne "0")
}
