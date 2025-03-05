# Azure VPN Gateway - Client Certificate Management Script

This PowerShell script helps you create, manage, and export client certificates for Azure VPN Gateway Point-to-Site (P2S) connections using certificate authentication.

## Script

`./Create-VpnClientCertificates.ps1`

## Instructions for Using the Script

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

## Azure VPN Gateway Configuration

After running the script:

1. Copy the Base64-encoded root certificate data from the text file
2. In the Azure Portal, navigate to your VPN Gateway → Point-to-site configuration
3. Add a new root certificate, paste the Base64 data, and save
4. Download the VPN client configuration package from the Azure Portal
5. Install the client certificate (.pfx) on each device that needs VPN access
6. Configure and connect using the downloaded VPN client

## Troubleshooting

- If you receive certificate store access errors, ensure you're running PowerShell as Administrator
- If client connections fail, verify that the client certificate was issued by the same root certificate uploaded to Azure
- Check certificate expiration dates if connections suddenly stop working
