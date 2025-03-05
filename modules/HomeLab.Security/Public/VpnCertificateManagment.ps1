<#
.SYNOPSIS
    VPN Certificate Management Module
.DESCRIPTION
    Provides functions to create and manage VPN certificates for HomeLab.
    Functions include creating a new VPN root certificate (with an initial client certificate),
    generating additional client certificates, and uploading a certificate to a VPN gateway.
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>

function New-VpnRootCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootCertName,
        
        [Parameter(Mandatory = $true)]
        [string]$ClientCertName,
        
        [switch]$CreateNewRoot
    )
    
    Write-Log "Creating new VPN root certificate: $RootCertName with client certificate: $ClientCertName" -Level INFO
    
    try {
        # Create a self-signed root certificate in the CurrentUser store valid for 5 years.
        $rootCert = New-SelfSignedCertificate -Subject "CN=$RootCertName" `
                                                -CertStoreLocation "Cert:\CurrentUser\My" `
                                                -KeyExportPolicy Exportable `
                                                -NotAfter (Get-Date).AddYears(5)
                                                
        if ($CreateNewRoot) {
            Write-Log "A new root certificate was created with thumbprint: $($rootCert.Thumbprint)" -Level INFO
        }
        
        # Export the root certificate as a PFX file (for demonstration, password is hardcoded)
        $pfxPath = "$env:TEMP\$RootCertName.pfx"
        $password = ConvertTo-SecureString -String "P@ssw0rd!" -Force -AsPlainText
        Export-PfxCertificate -Cert $rootCert -FilePath $pfxPath -Password $password | Out-Null
        Write-Log "Exported root certificate to: $pfxPath" -Level DEBUG
        
        # Immediately create an initial client certificate signed by the root certificate, valid for 2 years.
        $clientCert = New-SelfSignedCertificate -Subject "CN=$ClientCertName" `
                                                  -CertStoreLocation "Cert:\CurrentUser\My" `
                                                  -Signer $rootCert `
                                                  -KeyExportPolicy Exportable `
                                                  -NotAfter (Get-Date).AddYears(2)
        Write-Log "Created initial client certificate with thumbprint: $($clientCert.Thumbprint)" -Level INFO
        
        return @{ Success = $true; Message = "Root and initial client certificate created." }
    }
    catch {
        Write-Log "Error creating VPN root certificate: $_" -Level ERROR
        return @{ Success = $false; Message = "Failed to create root certificate." }
    }
}

function New-VpnClientCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootCertName,
        
        [Parameter(Mandatory = $true)]
        [string]$ClientCertName
    )
    
    Write-Log "Creating new VPN client certificate: $ClientCertName using root certificate: $RootCertName" -Level INFO
    
    try {
        # Retrieve the specified root certificate from the CurrentUser store.
        $rootCert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -eq "CN=$RootCertName" } | Select-Object -First 1
        
        if (-not $rootCert) {
            throw "Root certificate '$RootCertName' not found in certificate store."
        }
        
        # Create a new client certificate signed by the retrieved root certificate.
        $clientCert = New-SelfSignedCertificate -Subject "CN=$ClientCertName" `
                                                  -CertStoreLocation "Cert:\CurrentUser\My" `
                                                  -Signer $rootCert `
                                                  -KeyExportPolicy Exportable `
                                                  -NotAfter (Get-Date).AddYears(2)
        Write-Log "VPN client certificate created with thumbprint: $($clientCert.Thumbprint)" -Level INFO
        
        return @{ Success = $true; Message = "Client certificate created." }
    }
    catch {
        Write-Log "Error creating VPN client certificate: $_" -Level ERROR
        return @{ Success = $false; Message = "Failed to create client certificate." }
    }
}

function Add-AdditionalClientCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$NewClientName
    )
    
    Write-Log "Adding additional VPN client certificate: $NewClientName" -Level INFO
    
    try {
        # Retrieve the existing root certificate using a naming pattern (assumes the root subject contains 'vpn-root')
        $rootCert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -like "*vpn-root*" } | Select-Object -First 1
        
        if (-not $rootCert) {
            throw "No VPN root certificate found."
        }
        
        # Create a new client certificate signed by the root certificate.
        $clientCert = New-SelfSignedCertificate -Subject "CN=$NewClientName" `
                                                  -CertStoreLocation "Cert:\CurrentUser\My" `
                                                  -Signer $rootCert `
                                                  -KeyExportPolicy Exportable `
                                                  -NotAfter (Get-Date).AddYears(2)
        Write-Log "Additional VPN client certificate created with thumbprint: $($clientCert.Thumbprint)" -Level INFO
        
        return @{ Success = $true; Message = "Additional client certificate created." }
    }
    catch {
        Write-Log "Error adding additional VPN client certificate: $_" -Level ERROR
        return @{ Success = $false; Message = "Failed to add additional client certificate." }
    }
}

function Add-VpnGatewayCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string]$GatewayName,
        
        [Parameter(Mandatory = $true)]
        [string]$CertificateName,
        
        [Parameter(Mandatory = $true)]
        [string]$CertificateData
    )
    
    Write-Log "Uploading certificate '$CertificateName' to VPN Gateway '$GatewayName' in resource group '$ResourceGroupName'" -Level INFO
    
    try {
        # Construct the Azure CLI command to upload the certificate.
        $cmd = "az network vnet-gateway root-cert create --resource-group `"$ResourceGroupName`" --gateway-name `"$GatewayName`" --name `"$CertificateName`" --public-cert-data `"$CertificateData`""
        Write-Log "Executing command: $cmd" -Level DEBUG
        
        $result = Invoke-Expression $cmd
        
        Write-Log "VPN gateway certificate upload result: $result" -Level DEBUG
        return @{ Success = $true; Message = "VPN gateway certificate uploaded." }
    }
    catch {
        Write-Log "Error uploading VPN gateway certificate: $_" -Level ERROR
        return @{ Success = $false; Message = "Failed to upload VPN gateway certificate." }
    }
}

Export-ModuleMember -Function New-VpnRootCertificate, New-VpnClientCertificate, Add-AdditionalClientCertificate, Add-VpnGatewayCertificate
