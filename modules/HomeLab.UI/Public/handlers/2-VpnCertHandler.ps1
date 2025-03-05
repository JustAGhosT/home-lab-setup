<#
.SYNOPSIS
    VPN Certificate menu handler for HomeLab setup
.DESCRIPTION
    Processes user selections in the VPN certificate menu using the new VPN certificate management functions.
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>

function Invoke-VpnCertMenu {
    [CmdletBinding()]
    param()
    
    $selection = 0
    do {
        Show-VpnCertMenu
        $selection = Read-Host "Select an option"
        $params = Get-Configuration
        
        switch ($selection) {
            "1" {
                Write-Host "Creating new root certificate..." -ForegroundColor Cyan
                $rootCertName = "$($params.env)-$($params.project)-vpn-root"
                $clientCertName = "$($params.env)-$($params.project)-vpn-client"
                New-VpnRootCertificate -RootCertName $rootCertName -ClientCertName $clientCertName -CreateNewRoot
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "2" {
                Write-Host "Creating client certificate..." -ForegroundColor Cyan
                $rootCertName = "$($params.env)-$($params.project)-vpn-root"
                $clientCertName = Read-Host "Enter client certificate name"
                if ([string]::IsNullOrWhiteSpace($clientCertName)) {
                    $clientCertName = "$($params.env)-$($params.project)-vpn-client"
                }
                New-VpnClientCertificate -RootCertName $rootCertName -ClientCertName $clientCertName
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "3" {
                Write-Host "Adding client certificate to existing root..." -ForegroundColor Cyan
                $newClientName = Read-Host "Enter new client name"
                if (-not [string]::IsNullOrWhiteSpace($newClientName)) {
                    Add-AdditionalClientCertificate -NewClientName $newClientName
                }
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "4" {
                Write-Host "Uploading certificate to VPN Gateway..." -ForegroundColor Cyan
                $resourceGroup = "$($params.env)-$($params.loc)-rg-$($params.project)"
                $gatewayName = "$($params.env)-$($params.loc)-vpng-$($params.project)"
                $certName = "$($params.env)-$($params.project)-vpn-root"
                
                Write-Host "Select the Base64 encoded certificate file (.txt)..." -ForegroundColor Yellow
                $certFile = Read-Host "Enter path to certificate file"
                
                if (Test-Path $certFile) {
                    $certData = Get-Content $certFile -Raw
                    Add-VpnGatewayCertificate -ResourceGroupName $resourceGroup -GatewayName $gatewayName -CertificateName $certName -CertificateData $certData
                } else {
                    Write-Host "Certificate file not found." -ForegroundColor Red
                }
                
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "5" {
                Write-Host "Listing all certificates..." -ForegroundColor Cyan
                $rootCertName = "$($params.env)-$($params.project)-vpn-root"
                
                Write-Host "Root Certificates:" -ForegroundColor Yellow
                Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -like "CN=$rootCertName*" } | 
                    Format-Table -Property Subject, Thumbprint, NotBefore, NotAfter
                
                Write-Host "Client Certificates:" -ForegroundColor Yellow
                Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -like "CN=$($params.env)-$($params.project)-vpn-client*" } | 
                    Format-Table -Property Subject, Thumbprint, NotBefore, NotAfter
                
                Write-Host "Press any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
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

# Export functions if necessary
Export-ModuleMember -Function Invoke-VpnCertMenu
