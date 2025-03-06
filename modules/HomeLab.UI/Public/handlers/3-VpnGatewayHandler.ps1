<#
.SYNOPSIS
    VPN Gateway Menu Handler for HomeLab Setup
.DESCRIPTION
    Processes user selections in the VPN gateway menu using the new modular configuration
    and UI helpers. Options include checking gateway status, generating VPN client configuration,
    uploading certificates, and removing certificates.
.EXAMPLE
    Invoke-VpnGatewayMenu
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Invoke-VpnGatewayMenu {
    [CmdletBinding()]
    param()
    
    $selection = 0
    do {
        Show-VpnGatewayMenu
        $selection = Read-Host "Select an option"
        $config = Get-Configuration
        
        # Build resource names based on configuration
        $resourceGroup = "$($config.env)-$($config.loc)-rg-$($config.project)"
        $gatewayName   = "$($config.env)-$($config.loc)-vpng-$($config.project)"
        
        switch ($selection) {
            "1" {
                Write-Host "Checking VPN Gateway status..." -ForegroundColor Cyan
                
                $status = az network vnet-gateway show --resource-group $resourceGroup --name $gatewayName --query "properties.provisioningState" -o tsv 2>$null
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "VPN Gateway Status: $status" -ForegroundColor Green
                    
                    # Get additional details
                    $gatewayType = az network vnet-gateway show --resource-group $resourceGroup --name $gatewayName --query "gatewayType" -o tsv
                    $vpnType     = az network vnet-gateway show --resource-group $resourceGroup --name $gatewayName --query "vpnType" -o tsv
                    $sku         = az network vnet-gateway show --resource-group $resourceGroup --name $gatewayName --query "sku.name" -o tsv
                    
                    Write-Host "Gateway Type: $gatewayType" -ForegroundColor White
                    Write-Host "VPN Type: $vpnType" -ForegroundColor White
                    Write-Host "SKU: $sku" -ForegroundColor White
                }
                else {
                    Write-Host "VPN Gateway not found or error retrieving status." -ForegroundColor Red
                }
                
                Pause
            }
            "2" {
                Write-Host "Generating VPN client configuration..." -ForegroundColor Cyan
                
                $outputPath = Join-Path -Path $PWD -ChildPath "vpnclientconfiguration.zip"
                
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
                
                Pause
            }
            "3" {
                Write-Host "Uploading certificate to VPN Gateway..." -ForegroundColor Cyan
                $certName = "$($config.env)-$($config.project)-vpn-root"
                
                Write-Host "Select the Base64 encoded certificate file (.txt)..." -ForegroundColor Yellow
                $certFile = Read-Host "Enter path to certificate file"
                
                if (Test-Path $certFile) {
                    $certData = Get-Content $certFile -Raw
                    
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
                else {
                    Write-Host "Certificate file not found." -ForegroundColor Red
                }
                
                Pause
            }
            "4" {
                Write-Host "Removing certificate from VPN Gateway..." -ForegroundColor Cyan
                
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
