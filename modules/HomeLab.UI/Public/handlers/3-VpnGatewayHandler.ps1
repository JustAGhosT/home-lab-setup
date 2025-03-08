<#
.SYNOPSIS
    VPN Gateway Menu Handler for HomeLab Setup
.DESCRIPTION
    Processes user selections in the VPN gateway menu using the new modular configuration
    and UI helpers. Options include checking gateway status, generating VPN client configuration,
    uploading certificates, and removing certificates.
.PARAMETER ShowProgress
    If specified, shows a progress bar while loading the menu and performing operations.
.EXAMPLE
    Invoke-VpnGatewayMenu
.EXAMPLE
    Invoke-VpnGatewayMenu -ShowProgress
.NOTES
    Author: Jurie Smit
    Date: March 8, 2025
#>
function Invoke-VpnGatewayMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress
    )
    
    $selection = 0
    do {
        try {
            Show-VpnGatewayMenu -ShowProgress:$ShowProgress
        }
        catch {
            Write-Host "Error displaying VPN Gateway Menu: $_" -ForegroundColor Red
            break
        }
        
        $selection = Read-Host "Select an option"
        $config = Get-Configuration
        
        # Build resource names based on configuration
        $resourceGroup = "$($config.env)-$($config.loc)-rg-$($config.project)"
        $gatewayName   = "$($config.env)-$($config.loc)-vpng-$($config.project)"
        
        switch ($selection) {
            "1" {
                Write-Host "Checking VPN Gateway status..." -ForegroundColor Cyan
                
                if ($ShowProgress) {
                    # Create a progress task for checking gateway status
                    $task = Start-ProgressTask -Activity "Checking VPN Gateway Status" -TotalSteps 3 -ScriptBlock {
                        # Step 1: Connecting to Azure
                        $syncHash.Status = "Connecting to Azure..."
                        $syncHash.CurrentStep = 1
                        
                        # Step 2: Retrieving gateway information
                        $syncHash.Status = "Retrieving gateway information..."
                        $syncHash.CurrentStep = 2
                        
                        # Get the status
                        $status = az network vnet-gateway show --resource-group $resourceGroup --name $gatewayName --query "properties.provisioningState" -o tsv 2>$null
                        $exitCode = $LASTEXITCODE
                        
                        if ($exitCode -eq 0) {
                            # Step 3: Retrieving additional details
                            $syncHash.Status = "Retrieving additional details..."
                            $syncHash.CurrentStep = 3
                            
                            # Get additional details
                            $gatewayType = az network vnet-gateway show --resource-group $resourceGroup --name $gatewayName --query "gatewayType" -o tsv
                            $vpnType = az network vnet-gateway show --resource-group $resourceGroup --name $gatewayName --query "vpnType" -o tsv
                            $sku = az network vnet-gateway show --resource-group $resourceGroup --name $gatewayName --query "sku.name" -o tsv
                            
                            return @{
                                Success = $true
                                Status = $status
                                GatewayType = $gatewayType
                                VpnType = $vpnType
                                Sku = $sku
                            }
                        }
                        else {
                            return @{
                                Success = $false
                                ErrorMessage = "VPN Gateway not found or error retrieving status."
                            }
                        }
                    }
                    
                    $result = $task.Complete()
                    
                    if ($result.Success) {
                        Write-Host "VPN Gateway Status: $($result.Status)" -ForegroundColor Green
                        Write-Host "Gateway Type: $($result.GatewayType)" -ForegroundColor White
                        Write-Host "VPN Type: $($result.VpnType)" -ForegroundColor White
                        Write-Host "SKU: $($result.Sku)" -ForegroundColor White
                    }
                    else {
                        Write-Host $result.ErrorMessage -ForegroundColor Red
                    }
                }
                else {
                    # Original implementation without progress bar
                    $status = az network vnet-gateway show --resource-group $resourceGroup --name $gatewayName --query "properties.provisioningState" -o tsv 2>$null
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "VPN Gateway Status: $status" -ForegroundColor Green
                        
                        # Get additional details
                        $gatewayType = az network vnet-gateway show --resource-group $resourceGroup --name $gatewayName --query "gatewayType" -o tsv
                        $vpnType = az network vnet-gateway show --resource-group $resourceGroup --name $gatewayName --query "vpnType" -o tsv
                        $sku = az network vnet-gateway show --resource-group $resourceGroup --name $gatewayName --query "sku.name" -o tsv
                        
                        Write-Host "Gateway Type: $gatewayType" -ForegroundColor White
                        Write-Host "VPN Type: $vpnType" -ForegroundColor White
                        Write-Host "SKU: $sku" -ForegroundColor White
                    }
                    else {
                        Write-Host "VPN Gateway not found or error retrieving status." -ForegroundColor Red
                    }
                }
                
                Pause
            }
            "2" {
                Write-Host "Generating VPN client configuration..." -ForegroundColor Cyan
                
                $outputPath = Join-Path -Path $PWD -ChildPath "vpnclientconfiguration.zip"
                
                if ($ShowProgress) {
                    # Create a progress task for generating client configuration
                    $task = Start-ProgressTask -Activity "Generating VPN Client Configuration" -TotalSteps 4 -ScriptBlock {
                        # Step 1: Checking for required functions
                        $syncHash.Status = "Checking for required functions..."
                        $syncHash.CurrentStep = 1
                        
                        $useFunction = Get-Command Get-VpnClientConfiguration -ErrorAction SilentlyContinue
                        
                        # Step 2: Connecting to Azure
                        $syncHash.Status = "Connecting to Azure..."
                        $syncHash.CurrentStep = 2
                        
                        # Step 3: Locating VPN Gateway
                        $syncHash.Status = "Locating VPN Gateway..."
                        $syncHash.CurrentStep = 3
                        
                        # Step 4: Generating configuration
                        $syncHash.Status = "Generating configuration..."
                        $syncHash.CurrentStep = 4
                        
                        if ($useFunction) {
                            try {
                                Get-VpnClientConfiguration -ResourceGroupName $resourceGroup -GatewayName $gatewayName -OutputPath $outputPath
                                return @{
                                    Success = $true
                                    OutputPath = $outputPath
                                    UsedFunction = $true
                                }
                            }
                            catch {
                                return @{
                                    Success = $false
                                    ErrorMessage = "Error generating VPN client configuration: $_"
                                    UsedFunction = $true
                                }
                            }
                        }
                        else {
                            # Fallback to direct Azure CLI command
                            $result = az network vnet-gateway vpn-client generate --resource-group $resourceGroup --name $gatewayName --output-path $outputPath
                            
                            if ($LASTEXITCODE -eq 0) {
                                return @{
                                    Success = $true
                                    OutputPath = $outputPath
                                    UsedFunction = $false
                                }
                            }
                            else {
                                return @{
                                    Success = $false
                                    ErrorMessage = "Failed to generate VPN client configuration."
                                    UsedFunction = $false
                                }
                            }
                        }
                    }
                    
                    $result = $task.Complete()
                    
                    if ($result.Success) {
                        Write-Host "VPN client configuration generated successfully at: $($result.OutputPath)" -ForegroundColor Green
                    }
                    else {
                        if (-not $result.UsedFunction) {
                            Write-Host "Function Get-VpnClientConfiguration not found. Make sure the required module is imported." -ForegroundColor Red
                            Write-Host "Attempted to use Azure CLI directly..." -ForegroundColor Yellow
                        }
                        Write-Host $result.ErrorMessage -ForegroundColor Red
                    }
                }
                else {
                    # Original implementation without progress bar
                    # Assuming Get-VpnClientConfiguration is defined in another module
                    if (Get-Command Get-VpnClientConfiguration -ErrorAction SilentlyContinue) {
                        Get-VpnClientConfiguration -ResourceGroupName $resourceGroup -GatewayName $gatewayName -OutputPath $outputPath
                    }
                    else {
                        Write-Host "Function Get-VpnClientConfiguration not found. Make sure the required module is imported." -ForegroundColor Red
                        
                        # Fallback to direct Azure CLI command
                        Write-Host "Attempting to use Azure CLI directly..." -ForegroundColor Yellow
                        $result = az network vnet-gateway vpn-client generate --resource-group $resourceGroup --name $gatewayName --output-path $outputPath
                        
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "VPN client configuration generated successfully at: $outputPath" -ForegroundColor Green
                        }
                        else {
                            Write-Host "Failed to generate VPN client configuration." -ForegroundColor Red
                        }
                    }
                }
                
                Pause
            }
            "3" {
                Write-Host "Uploading certificate to VPN Gateway..." -ForegroundColor Cyan
                $certName = "$($config.env)-$($config.project)-vpn-root"
                
                Write-Host "Select the Base64 encoded certificate file (.txt)..." -ForegroundColor Yellow
                $certFile = Read-Host "Enter path to certificate file"
                
                if (Test-Path $certFile) {
                    $certData = Get-Content $certFile -Raw
                    
                    if ($ShowProgress) {
                        # Create a progress task for uploading certificate
                        $task = Start-ProgressTask -Activity "Uploading Certificate to VPN Gateway" -TotalSteps 4 -ScriptBlock {
                            # Step 1: Checking for required functions
                            $syncHash.Status = "Checking for required functions..."
                            $syncHash.CurrentStep = 1
                            
                            $useFunction = Get-Command Add-VpnGatewayCertificate -ErrorAction SilentlyContinue
                            
                            # Step 2: Validating certificate data
                            $syncHash.Status = "Validating certificate data..."
                            $syncHash.CurrentStep = 2
                            
                            # Step 3: Connecting to Azure
                            $syncHash.Status = "Connecting to Azure..."
                            $syncHash.CurrentStep = 3
                            
                            # Step 4: Uploading certificate
                            $syncHash.Status = "Uploading certificate..."
                            $syncHash.CurrentStep = 4
                            
                            if ($useFunction) {
                                try {
                                    Add-VpnGatewayCertificate -ResourceGroupName $resourceGroup -GatewayName $gatewayName -CertificateName $certName -CertificateData $certData
                                    return @{
                                        Success = $true
                                        UsedFunction = $true
                                    }
                                }
                                catch {
                                    return @{
                                        Success = $false
                                        ErrorMessage = "Error uploading certificate: $_"
                                        UsedFunction = $true
                                    }
                                }
                            }
                            else {
                                # Fallback to direct Azure CLI command
                                $result = az network vnet-gateway root-cert create --resource-group $resourceGroup --gateway-name $gatewayName --name $certName --public-cert-data $certData
                                
                                if ($LASTEXITCODE -eq 0) {
                                    return @{
                                        Success = $true
                                        UsedFunction = $false
                                    }
                                }
                                else {
                                    return @{
                                        Success = $false
                                        ErrorMessage = "Failed to upload certificate."
                                        UsedFunction = $false
                                    }
                                }
                            }
                        }
                        
                        $result = $task.Complete()
                        
                        if ($result.Success) {
                            Write-Host "Certificate uploaded successfully." -ForegroundColor Green
                        }
                        else {
                            if (-not $result.UsedFunction) {
                                Write-Host "Function Add-VpnGatewayCertificate not found. Make sure the required module is imported." -ForegroundColor Red
                                Write-Host "Attempted to use Azure CLI directly..." -ForegroundColor Yellow
                            }
                            Write-Host $result.ErrorMessage -ForegroundColor Red
                        }
                    }
                    else {
                        # Original implementation without progress bar
                        # Assuming Add-VpnGatewayCertificate is defined in another module
                        if (Get-Command Add-VpnGatewayCertificate -ErrorAction SilentlyContinue) {
                            Add-VpnGatewayCertificate -ResourceGroupName $resourceGroup -GatewayName $gatewayName -CertificateName $certName -CertificateData $certData
                        }
                        else {
                            Write-Host "Function Add-VpnGatewayCertificate not found. Make sure the required module is imported." -ForegroundColor Red
                            
                            # Fallback to direct Azure CLI command
                            Write-Host "Attempting to use Azure CLI directly..." -ForegroundColor Yellow
                            $result = az network vnet-gateway root-cert create --resource-group $resourceGroup --gateway-name $gatewayName --name $certName --public-cert-data $certData
                            
                            if ($LASTEXITCODE -eq 0) {
                                Write-Host "Certificate uploaded successfully." -ForegroundColor Green
                            }
                            else {
                                Write-Host "Failed to upload certificate." -ForegroundColor Red
                            }
                        }
                    }
                }
                else {
                    Write-Host "Certificate file not found." -ForegroundColor Red
                }
                
                Pause
            }
            "4" {
                Write-Host "Removing certificate from VPN Gateway..." -ForegroundColor Cyan
                
                if ($ShowProgress) {
                    # Create a progress task for listing and removing certificates
                    $task = Start-ProgressTask -Activity "Managing VPN Gateway Certificates" -TotalSteps 3 -ScriptBlock {
                        # Step 1: Connecting to Azure
                        $syncHash.Status = "Connecting to Azure..."
                        $syncHash.CurrentStep = 1
                        
                        # Step 2: Listing certificates
                        $syncHash.Status = "Listing certificates..."
                        $syncHash.CurrentStep = 2
                        
                        $certs = az network vnet-gateway root-cert list --resource-group $resourceGroup --gateway-name $gatewayName --query "[].name" -o tsv
                        
                        return @{
                            Certificates = $certs
                        }
                    }
                    
                    $result = $task.Complete()
                    
                    Write-Host "Existing certificates:" -ForegroundColor Yellow
                    if ($result.Certificates) {
                        $result.Certificates -split "`n" | ForEach-Object { Write-Host "- $_" -ForegroundColor White }
                        
                        $certToRemove = Read-Host "Enter certificate name to remove"
                        
                        if (-not [string]::IsNullOrWhiteSpace($certToRemove)) {
                            # Create another progress task for removing the certificate
                            $removeTask = Start-ProgressTask -Activity "Removing Certificate" -TotalSteps 2 -ScriptBlock {
                                # Step 1: Connecting to Azure
                                $syncHash.Status = "Connecting to Azure..."
                                $syncHash.CurrentStep = 1
                                
                                # Step 2: Removing certificate
                                $syncHash.Status = "Removing certificate..."
                                $syncHash.CurrentStep = 2
                                
                                $result = az network vnet-gateway root-cert delete --resource-group $resourceGroup --gateway-name $gatewayName --name $certToRemove
                                
                                return @{
                                    Success = ($LASTEXITCODE -eq 0)
                                }
                            }
                            
                            $removeResult = $removeTask.Complete()
                            
                            if ($removeResult.Success) {
                                Write-Host "Certificate removed successfully." -ForegroundColor Green
                            }
                            else {
                                Write-Host "Failed to remove certificate." -ForegroundColor Red
                            }
                        }
                    }
                    else {
                        Write-Host "No certificates found." -ForegroundColor Yellow
                    }
                }
                else {
                    # Original implementation without progress bar
                    Write-Host "Existing certificates:" -ForegroundColor Yellow
                    $certs = az network vnet-gateway root-cert list --resource-group $resourceGroup --gateway-name $gatewayName --query "[].name" -o tsv
                    
                    if ($certs) {
                        $certs -split "`n" | ForEach-Object { Write-Host "- $_" -ForegroundColor White }
                        
                        $certToRemove = Read-Host "Enter certificate name to remove"
                        
                        if (-not [string]::IsNullOrWhiteSpace($certToRemove)) {
                            $result = az network vnet-gateway root-cert delete --resource-group $resourceGroup --gateway-name $gatewayName --name $certToRemove
                            
                            if ($LASTEXITCODE -eq 0) {
                                Write-Host "Certificate removed successfully." -ForegroundColor Green
                            }
                            else {
                                Write-Host "Failed to remove certificate." -ForegroundColor Red
                            }
                        }
                    }
                    else {
                        Write-Host "No certificates found." -ForegroundColor Yellow
                    }
                }
                
                Pause
            }
            "0" {
                # Return to main menu; do nothing.
            }
            default {
                Write-Host "Invalid option. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($selection -ne "0")
}
