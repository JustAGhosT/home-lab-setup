<#
.SYNOPSIS
    VPN Certificate Management Functions
.DESCRIPTION
    Provides functions to create and manage VPN certificates for HomeLab.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>

function New-VpnRootCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootCertName,
        
        [Parameter(Mandatory = $true)]
        [string]$ClientCertName,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateNewRoot,
        
        [Parameter(Mandatory = $false)]
        [string]$ExportPath = $env:TEMP,
        
        [Parameter(Mandatory = $false)]
        [securestring]$CertPassword
    )
    
    Write-Log "Creating new VPN root certificate: $RootCertName with client certificate: $ClientCertName" -Level INFO
    
    try {
        # Create a self-signed root certificate in the CurrentUser store valid for 5 years.
        $rootCert = New-SelfSignedCertificate -Subject "CN=$RootCertName" `
                                              -CertStoreLocation "Cert:\CurrentUser\My" `
                                              -KeyExportPolicy Exportable `
                                              -KeyUsage CertSign, CRLSign, DigitalSignature `
                                              -KeyUsageProperty All `
                                              -KeyLength 2048 `
                                              -HashAlgorithm SHA256 `
                                              -NotAfter (Get-Date).AddYears(5)
                                                
        if ($CreateNewRoot) {
            Write-Log "A new root certificate was created with thumbprint: $($rootCert.Thumbprint)" -Level INFO
        }
        
        # Export the root certificate as a PFX file with a secure password
        $pfxPath = Join-Path -Path $ExportPath -ChildPath "$RootCertName.pfx"
        
        # If no password is provided, prompt for one securely
        if (-not $CertPassword) {
            $CertPassword = Read-Host -Prompt "Enter password for certificate export" -AsSecureString
        }
        
        Export-PfxCertificate -Cert $rootCert -FilePath $pfxPath -Password $CertPassword | Out-Null
        Write-Log "Exported root certificate to: $pfxPath" -Level INFO
        
        # Also export the public certificate (CER) for VPN gateway configuration
        $cerPath = Join-Path -Path $ExportPath -ChildPath "$RootCertName.cer"
        Export-Certificate -Cert $rootCert -FilePath $cerPath -Type CERT | Out-Null
        Write-Log "Exported public certificate to: $cerPath" -Level INFO
        
        # Immediately create an initial client certificate signed by the root certificate, valid for 2 years.
        $clientCert = New-SelfSignedCertificate -Subject "CN=$ClientCertName" `
                                               -CertStoreLocation "Cert:\CurrentUser\My" `
                                               -Signer $rootCert `
                                               -KeyExportPolicy Exportable `
                                               -KeyLength 2048 `
                                               -HashAlgorithm SHA256 `
                                               -NotAfter (Get-Date).AddYears(2)
        
        Write-Log "Created initial client certificate with thumbprint: $($clientCert.Thumbprint)" -Level INFO
        
        # Export the client certificate as well
        $clientPfxPath = Join-Path -Path $ExportPath -ChildPath "$ClientCertName.pfx"
        Export-PfxCertificate -Cert $clientCert -FilePath $clientPfxPath -Password $CertPassword | Out-Null
        Write-Log "Exported client certificate to: $clientPfxPath" -Level INFO
        
        return @{
            Success = $true
            Message = "Root and initial client certificate created."
            RootCertThumbprint = $rootCert.Thumbprint
            ClientCertThumbprint = $clientCert.Thumbprint
            RootCertPath = $pfxPath
            RootCerPath = $cerPath
            ClientCertPath = $clientPfxPath
        }
    }
    catch {
        Write-Log "Error creating VPN root certificate: $_" -Level ERROR
        return @{ Success = $false; Message = "Failed to create root certificate: $_"; Error = $_ }
    }
}

function New-VpnClientCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootCertName,
        
        [Parameter(Mandatory = $true)]
        [string]$ClientCertName,
        
        [Parameter(Mandatory = $false)]
        [string]$ExportPath = $env:TEMP,
        
        [Parameter(Mandatory = $false)]
        [securestring]$CertPassword
    )
    
    Write-Log "Creating new VPN client certificate: $ClientCertName using root certificate: $RootCertName" -Level INFO
    
    try {
        # Retrieve the specified root certificate from the CurrentUser store.
        $rootCert = Get-ChildItem -Path Cert:\CurrentUser\My | 
                    Where-Object { $_.Subject -eq "CN=$RootCertName" } | 
                    Select-Object -First 1
        
        if (-not $rootCert) {
            throw "Root certificate '$RootCertName' not found in certificate store."
        }
        
        # Create a new client certificate signed by the retrieved root certificate.
        $clientCert = New-SelfSignedCertificate -Subject "CN=$ClientCertName" `
                                               -CertStoreLocation "Cert:\CurrentUser\My" `
                                               -Signer $rootCert `
                                               -KeyExportPolicy Exportable `
                                               -KeyLength 2048 `
                                               -HashAlgorithm SHA256 `
                                               -NotAfter (Get-Date).AddYears(2)
        
        Write-Log "VPN client certificate created with thumbprint: $($clientCert.Thumbprint)" -Level INFO
        
        # If a password was provided, export the certificate
        if ($ExportPath) {
            $clientPfxPath = Join-Path -Path $ExportPath -ChildPath "$ClientCertName.pfx"
            
            # If no password is provided, prompt for one securely
            if (-not $CertPassword) {
                $CertPassword = Read-Host -Prompt "Enter password for certificate export" -AsSecureString
            }
            
            Export-PfxCertificate -Cert $clientCert -FilePath $clientPfxPath -Password $CertPassword | Out-Null
            Write-Log "Exported client certificate to: $clientPfxPath" -Level INFO
            
            return @{
                Success = $true
                Message = "Client certificate created and exported."
                ClientCertThumbprint = $clientCert.Thumbprint
                ClientCertPath = $clientPfxPath
            }
        }
        
        return @{
            Success = $true
            Message = "Client certificate created."
            ClientCertThumbprint = $clientCert.Thumbprint
        }
    }
    catch {
        Write-Log "Error creating VPN client certificate: $_" -Level ERROR
        return @{ Success = $false; Message = "Failed to create client certificate: $_"; Error = $_ }
    }
}

function New-AdditionalClientCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$NewClientName,
        
        [Parameter(Mandatory = $false)]
        [string]$RootCertPattern = "*vpn-root*",
        
        [Parameter(Mandatory = $false)]
        [string]$ExportPath = $env:TEMP,
        
        [Parameter(Mandatory = $false)]
        [securestring]$CertPassword
    )
    
    Write-Log "Adding additional VPN client certificate: $NewClientName" -Level INFO
    
    try {
        # Retrieve the existing root certificate using the provided pattern
        $rootCert = Get-ChildItem -Path Cert:\CurrentUser\My | 
                    Where-Object { $_.Subject -like "CN=$RootCertPattern" -or $_.Subject -like $RootCertPattern } | 
                    Select-Object -First 1
        
        if (-not $rootCert) {
            throw "No VPN root certificate found matching pattern '$RootCertPattern'."
        }
        
        Write-Log "Found root certificate: $($rootCert.Subject) with thumbprint: $($rootCert.Thumbprint)" -Level DEBUG
        
        # Create a new client certificate signed by the root certificate.
        $clientCert = New-SelfSignedCertificate -Subject "CN=$NewClientName" `
                                               -CertStoreLocation "Cert:\CurrentUser\My" `
                                               -Signer $rootCert `
                                               -KeyExportPolicy Exportable `
                                               -KeyLength 2048 `
                                               -HashAlgorithm SHA256 `
                                               -NotAfter (Get-Date).AddYears(2)
        
        Write-Log "Additional VPN client certificate created with thumbprint: $($clientCert.Thumbprint)" -Level INFO
        
        # If a path was provided, export the certificate
        if ($ExportPath) {
            $clientPfxPath = Join-Path -Path $ExportPath -ChildPath "$NewClientName.pfx"
            
            # If no password is provided, prompt for one securely
            if (-not $CertPassword) {
                $CertPassword = Read-Host -Prompt "Enter password for certificate export" -AsSecureString
            }
            
            Export-PfxCertificate -Cert $clientCert -FilePath $clientPfxPath -Password $CertPassword | Out-Null
            Write-Log "Exported client certificate to: $clientPfxPath" -Level INFO
            
            return @{
                Success = $true
                Message = "Additional client certificate created and exported."
                ClientCertThumbprint = $clientCert.Thumbprint
                ClientCertPath = $clientPfxPath
            }
        }
        
        return @{
            Success = $true
            Message = "Additional client certificate created."
            ClientCertThumbprint = $clientCert.Thumbprint
        }
    }
    catch {
        Write-Log "Error adding additional VPN client certificate: $_" -Level ERROR
        return @{ Success = $false; Message = "Failed to add additional client certificate: $_"; Error = $_ }
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
        # First check if Azure CLI is installed and logged in
        $azCheck = Invoke-Expression "az --version" -ErrorAction SilentlyContinue
        
        if (-not $azCheck) {
            throw "Azure CLI is not installed or not in the PATH. Please install Azure CLI and try again."
        }
        
        # Check if user is logged in
        $loginCheck = Invoke-Expression "az account show" -ErrorAction SilentlyContinue
        
        if (-not $loginCheck) {
            Write-Log "Not logged in to Azure. Prompting for login." -Level WARNING
            Invoke-Expression "az login" | Out-Null
        }
        
        # Construct the Azure CLI command to upload the certificate.
        $cmd = "az network vnet-gateway root-cert create --resource-group `"$ResourceGroupName`" --gateway-name `"$GatewayName`" --name `"$CertificateName`" --public-cert-data `"$CertificateData`""
        Write-Log "Executing command: $cmd" -Level DEBUG
        
        $result = Invoke-Expression $cmd
        
        if ($result) {
            Write-Log "VPN gateway certificate uploaded successfully" -Level INFO
            return @{ 
                Success = $true
                Message = "VPN gateway certificate uploaded."
                Result = $result
            }
        } else {
            throw "Command executed but returned no result."
        }
    }
    catch {
        Write-Log "Error uploading VPN gateway certificate: $_" -Level ERROR
        return @{ 
            Success = $false
            Message = "Failed to upload VPN gateway certificate: $_"
            Error = $_ 
        }
    }
}

function Get-VpnCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$CertificatePattern,
        
        [Parameter(Mandatory = $false)]
        [switch]$RootCertificatesOnly,
        
        [Parameter(Mandatory = $false)]
        [switch]$ClientCertificatesOnly
    )
    
    Write-Log "Retrieving VPN certificates from certificate store" -Level INFO
    
    try {
        $certificates = Get-ChildItem -Path Cert:\CurrentUser\My
        
        # Filter by pattern if provided
        if ($CertificatePattern) {
            $certificates = $certificates | Where-Object { $_.Subject -like "*$CertificatePattern*" }
        }
        
        # Filter by certificate type if requested
        if ($RootCertificatesOnly) {
            $certificates = $certificates | Where-Object { $_.HasPrivateKey -and $_.Subject -like "*vpn-root*" }
        }
        
        if ($ClientCertificatesOnly) {
            $certificates = $certificates | Where-Object { $_.HasPrivateKey -and $_.Subject -notlike "*vpn-root*" }
        }
        
        Write-Log "Retrieved $($certificates.Count) certificates matching criteria" -Level INFO
        
        return $certificates
    }
    catch {
        Write-Log "Error retrieving VPN certificates: $_" -Level ERROR
        return $null
    }
}
