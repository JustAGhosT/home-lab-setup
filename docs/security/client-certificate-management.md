# Azure VPN Gateway - Client Certificate Management Guide

This comprehensive guide covers the creation, management, and troubleshooting of client certificates for Azure VPN Gateway Point-to-Site (P2S) connections using certificate authentication.

## Table of Contents

- [Certificate Management Script](#certificate-management-script)
- [Manual Certificate Management](#manual-certificate-management)
- [Certificate Lifecycle Management](#certificate-lifecycle-management)
- [Troubleshooting Certificate Issues](#troubleshooting-certificate-issues)
- [Security Best Practices](#security-best-practices)

## Certificate Management Script

### Script Overview

The `Create-VpnClientCertificates.ps1` script automates the process of creating and managing certificates for VPN authentication.

### Basic Usage

1. Open PowerShell as Administrator
2. Navigate to the directory containing the script
3. Run the script with default parameters:

```powershell
.\Create-VpnClientCertificates.ps1
```

### Advanced Usage

Create certificates with custom names and export path:

```powershell
.\Create-VpnClientCertificates.ps1 -RootCertName "CompanyVPNRoot" -ClientCertName "UserLaptop" -ExportPath "C:\VPNCerts"
```

Create a new root certificate even if one exists:

```powershell
.\Create-VpnClientCertificates.ps1 -CreateNewRoot -RootCertName "NewRootCert"
```

Specify a password for the client certificate:

```powershell
.\Create-VpnClientCertificates.ps1 -ClientCertPassword "YourSecurePassword"
```

### Creating Additional Client Certificates

To create additional client certificates using the same root certificate:

```powershell
# First, run the script to create the root certificate
.\Create-VpnClientCertificates.ps1

# Then, use the Add-AdditionalClientCertificate function
. .\Create-VpnClientCertificates.ps1
Add-AdditionalClientCertificate -NewClientName "SecondDevice" -ClientPassword "SecurePass123"
```

## Manual Certificate Management

If you prefer to manage certificates manually or need more control over the process, follow these steps:

### Creating a Root Certificate

```powershell
$rootCertName = "P2SRootCert"
$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
  -Subject "CN=$rootCertName" -KeyExportPolicy Exportable `
  -HashAlgorithm sha256 -KeyLength 2048 `
  -CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign
```

### Creating a Client Certificate

```powershell
$clientCertName = "P2SClientCert"
New-SelfSignedCertificate -Type Custom -DnsName $clientCertName -KeySpec Signature `
  -Subject "CN=$clientCertName" -KeyExportPolicy Exportable `
  -HashAlgorithm sha256 -KeyLength 2048 `
  -CertStoreLocation "Cert:\CurrentUser\My" `
  -Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")
```

### Exporting Certificates

#### Export Root Certificate (Public Key)

```powershell
$certPath = "C:\Certs\$rootCertName.cer"
Export-Certificate -Cert $cert -FilePath $certPath
```

#### Get Base64 Encoded Data for Azure

```powershell
$rootCertData = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($certPath))
$rootCertData | Out-File -FilePath "C:\Certs\$rootCertName.txt"
```

#### Export Client Certificate with Private Key

```powershell
$password = ConvertTo-SecureString -String "YourSecurePassword" -Force -AsPlainText
$clientCert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -eq "CN=$clientCertName" }
Export-PfxCertificate -Cert $clientCert -FilePath "C:\Certs\$clientCertName.pfx" -Password $password
```

## Certificate Lifecycle Management

### Finding Existing Certificates

```powershell
# Find root certificates
Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -like "*RootCert*" -and $_.HasPrivateKey }

# Find client certificates
Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -like "*ClientCert*" -and $_.HasPrivateKey }
```

### Revoking a Client Certificate

1. Create a certificate revocation list (CRL)
2. Upload the CRL to Azure VPN Gateway
3. Remove the certificate from the client device

```powershell
# Note: For Azure VPN Gateway, certificate revocation is managed through the Azure Portal
# 1. Navigate to VPN Gateway → Point-to-site configuration → Revoked certificates
# 2. Add the certificate thumbprint to revoke access
# 3. Remove the certificate from client devices manually

# To get certificate thumbprint for revocation:
$clientCert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -eq "CN=P2SClientCert" }
Write-Host "Certificate thumbprint to revoke: $($clientCert.Thumbprint)"
```

### Renewing Certificates

Best practice is to renew certificates before they expire:

```powershell
# Check certificate expiration
$cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -eq "CN=P2SRootCert" }
$daysUntilExpiration = ($cert.NotAfter - (Get-Date)).Days
Write-Host "Certificate expires in $daysUntilExpiration days"

# If expiration is approaching, create new certificates
if ($daysUntilExpiration -lt 30) {
    Write-Host "Certificate will expire soon. Creating new certificates..."
    .\Create-VpnClientCertificates.ps1 -CreateNewRoot -RootCertName "P2SRootCert_New"
}
```

## Troubleshooting Certificate Issues

### Common Issues and Solutions

1. **Certificate Not Trusted**
   - Ensure the client certificate is issued by the same root certificate uploaded to Azure
   - Verify the root certificate is properly installed in the "Trusted Root Certification Authorities" store

2. **Certificate Missing Private Key**
   - Ensure the certificate was exported with the private key (PFX format)
   - Check that the certificate was imported correctly with the private key

3. **Certificate Expiration**
   - Verify certificate expiration dates
   - Create new certificates before expiration

4. **Access Denied When Creating Certificates**
   - Run PowerShell as Administrator
   - Check user permissions on certificate stores

### Diagnostic Commands

```powershell
# Verify certificate exists and has private key
$certThumbprint = "YOUR_CERTIFICATE_THUMBPRINT"
$cert = Get-Item -Path "Cert:\CurrentUser\My\$certThumbprint"
$cert.HasPrivateKey

# Check certificate purpose/extensions
$cert.Extensions | Where-Object { $_.Oid.FriendlyName -eq "Enhanced Key Usage" }

# Verify certificate chain
$chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
$chain.Build($cert)
$chain.ChainElements | ForEach-Object { $_.Certificate }
```

## Security Best Practices

1. **Use Strong Certificate Parameters**
   - Use SHA256 or stronger hash algorithms
   - Use 2048-bit or longer key length
   - Include appropriate key usage extensions

2. **Protect Private Keys**
   - Use strong passwords for PFX files
   - Store certificates securely
   - Consider using hardware security tokens for high-security environments

3. **Certificate Rotation**
   - Establish a regular certificate rotation schedule
   - Maintain a certificate inventory
   - Automate certificate lifecycle management where possible

4. **Least Privilege**
   - Issue client certificates only to authorized users
   - Revoke certificates when no longer needed
   - Consider using short-lived certificates for temporary access

5. **Audit and Monitoring**
   - Keep records of certificate issuance and revocation
   - Monitor for unauthorized certificate usage
   - Implement alerting for certificate expiration

## Azure VPN Gateway Configuration

After generating certificates:

1. Copy the Base64-encoded root certificate data from the text file
2. In the Azure Portal, navigate to your VPN Gateway → Point-to-site configuration
3. Add a new root certificate, paste the Base64 data, and save
4. Download the VPN client configuration package from the Azure Portal
5. Install the client certificate (.pfx) on each device that needs VPN access
6. Configure and connect using the downloaded VPN client

For more advanced VPN Gateway configuration options, refer to the [VPN Gateway Advanced Configuration Guide](VPN-GATEWAY.README.md).
