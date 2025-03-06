<#
.SYNOPSIS
    VPN Certificate menu handler for HomeLab setup
.DESCRIPTION
    Processes user selections in the VPN certificate menu using the new VPN certificate management functions.
.EXAMPLE
    Invoke-VpnCertMenu
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Invoke-VpnCertMenu {
    [CmdletBinding()]
    param()
    
    $selection = 0
    do {
        Show-VpnCertMenu
        $selection = Read-Host "Select an option"
        $config = Get-Configuration
        
        switch ($selection) {
            "1" {
                Write-Host "Creating new root certificate..." -ForegroundColor Cyan
                $rootCertName = "$($config.env)-$($config.project)-vpn-root"
                $clientCertName = "$($config.env)-$($config.project)-vpn-client"
                
                # Assuming New-VpnRootCertificate is defined in another module
                if (Get-Command New-VpnRootCertificate -ErrorAction SilentlyContinue) {
                    New-VpnRootCertificate -RootCertName $rootCertName -ClientCertName $clientCertName -CreateNewRoot
                }
                else {
                    Write-Host "Function New-VpnRootCertificate not found. Make sure the required module is imported." -ForegroundColor Red
                }
                
                Pause
            }
            "2" {
                Write-Host "Creating client certificate..." -ForegroundColor Cyan
                $rootCertName = "$($config.env)-$($config.project)-vpn-root"
                $clientCertName = Read-Host "Enter client certificate name"
                if ([string]::IsNullOrWhiteSpace($clientCertName)) {
                    $clientCertName = "$($config.env)-$($config.project)-vpn-client"
                }
                
                # Assuming New-VpnClientCertificate is defined in another module
                if (Get-Command New-VpnClientCertificate -ErrorAction SilentlyContinue) {
                    New-VpnClientCertificate -RootCertName $rootCertName -ClientCertName $clientCertName
                }
                else {
                    Write-Host "Function New-VpnClientCertificate not found. Make sure the required module is imported." -ForegroundColor Red
                }
                
                Pause
            }
            "3" {
                Write-Host "Adding client certificate to existing root..." -ForegroundColor Cyan
                $newClientName = Read-Host "Enter new client name"
                if (-not [string]::IsNullOrWhiteSpace($newClientName)) {
                    # Assuming Add-AdditionalClientCertificate is defined in another module
                    if (Get-Command Add-AdditionalClientCertificate -ErrorAction SilentlyContinue) {
                        Add-AdditionalClientCertificate -NewClientName $newClientName
                    }
                    else {
                        Write-Host "Function Add-AdditionalClientCertificate not found. Make sure the required module is imported." -ForegroundColor Red
                    }
                }
                
                Pause
            }
            "4" {
                Write-Host "Uploading certificate to VPN Gateway..." -ForegroundColor Cyan
                $resourceGroup = "$($config.env)-$($config.loc)-rg-$($config.project)"
                $gatewayName = "$($config.env)-$($config.loc)-vpng-$($config.project)"
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
                    }
                } else {
                    Write-Host "Certificate file not found." -ForegroundColor Red
                }
                
                Pause
            }
            "5" {
                Write-Host "Listing all certificates..." -ForegroundColor Cyan
                $rootCertName = "$($config.env)-$($config.project)-vpn-root"
                
                Write-Host "Root Certificates:" -ForegroundColor Yellow
                Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -like "CN=$rootCertName*" } | 
                    Format-Table -Property Subject, Thumbprint, NotBefore, NotAfter
                
                Write-Host "Client Certificates:" -ForegroundColor Yellow
                Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -like "CN=$($config.env)-$($config.project)-vpn-client*" } | 
                    Format-Table -Property Subject, Thumbprint, NotBefore, NotAfter
                
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
