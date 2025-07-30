# Azure VPN Gateway Advanced Configuration Guide

This comprehensive guide covers advanced configuration options for Azure VPN Gateway point-to-site (P2S) connections, including authentication methods, custom client configurations, and deployment best practices for your homelab environment.

## Table of Contents

- [Authentication Methods](#authentication-methods)
  - [Certificate Authentication](#certificate-authentication)
  - [Azure AD Authentication](#azure-ad-authentication)
  - [RADIUS Authentication](#radius-authentication)
- [Custom Client Configurations](#custom-client-configurations)
  - [Split Tunneling](#split-tunneling-configuration)
  - [Custom DNS Servers](#custom-dns-servers)
  - [Client Protocols](#client-protocols)
  - [Custom Routes](#custom-routes)
- [Deployment Examples](#deployment-examples)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)

## Authentication Methods

### Certificate Authentication

Certificate authentication uses certificates to authenticate VPN clients. This method is widely compatible and doesn't require additional Azure services.

#### Certificate Bicep Template

```bicep
param rootCertData string // Base64-encoded .cer public certificate data
param rootCertName string = 'P2SRootCert'

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = {
  // ... other properties
  properties: {
    // ... other properties
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          vpnClientAddressPoolPrefix
        ]
      }
      vpnClientRootCertificates: [
        {
          name: rootCertName
          properties: {
            publicCertData: rootCertData
          }
        }
      ]
    }
  }
}
```

#### Certificate Generation Process

1. **Generate a self-signed root certificate**:
   ```powershell
   $cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
     -Subject "CN=P2SRootCert" -KeyExportPolicy Exportable `
     -HashAlgorithm sha256 -KeyLength 2048 `
     -CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign
   ```

2. **Generate a client certificate**:
   ```powershell
   New-SelfSignedCertificate -Type Custom -DnsName P2SChildCert -KeySpec Signature `
     -Subject "CN=P2SChildCert" -KeyExportPolicy Exportable `
     -HashAlgorithm sha256 -KeyLength 2048 `
     -CertStoreLocation "Cert:\CurrentUser\My" `
     -Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")
   ```

3. **Export the root certificate public key** (.cer file):
   ```powershell
   $certPath = "C:\certs\P2SRootCert.cer"
   Export-Certificate -Cert $cert -FilePath $certPath
   $rootCertData = [System.Convert]::ToBase64String(
     [System.IO.File]::ReadAllBytes($certPath)
   )
   ```

4. **Export client certificate with private key** (.pfx file) for installation on client devices:
   ```powershell
   # Generate a secure password or prompt user
$password = Read-Host -AsSecureString -Prompt "Enter a secure password for the certificate"
OR use a generated password
$password = ConvertTo-SecureString -String (New-Guid).Guid -Force -AsPlainText
   Export-PfxCertificate -Cert "Cert:\CurrentUser\My\CLIENT_CERT_THUMBPRINT" `
     -FilePath "C:\certs\P2SClientCert.pfx" -Password $password
   ```

### Azure AD Authentication

Azure AD authentication allows users to connect using their Azure AD credentials, providing seamless integration with your existing identity system and enabling conditional access policies.

#### Requirements

- VpnGw1 or higher SKU gateway (not supported on Basic SKU)
- Azure AD tenant with appropriate permissions
- OpenVPN protocol support on client devices

#### Implementation in Bicep

```bicep
param tenantId string // Your Azure AD tenant ID
param audienceId string = '41b23e61-6c1e-4545-b367-cd054e0ed4b4' // Azure VPN client ID
param issuerId string = 'https://sts.windows.net/${tenantId}/'

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = {
  // ... other properties
  properties: {
    // ... other properties
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          vpnClientAddressPoolPrefix
        ]
      }
      aadTenant: issuerId
      aadAudience: audienceId
      aadIssuer: issuerId
      vpnClientProtocols: [
        'OpenVPN'  // Azure AD auth requires OpenVPN protocol
      ]
    }
  }
}
```

#### Azure AD Integration Steps

1. **Register the Azure VPN application in your tenant**:
   ```powershell
   Connect-AzAccount
   $app = New-AzADApplication -DisplayName "AzureVPN"
   $spn = New-AzADServicePrincipal -ApplicationId $app.ApplicationId
   ```

2. **Grant admin consent** through the Azure portal:
   - Navigate to Azure Active Directory → App registrations → Your VPN app
   - Go to API permissions → Grant admin consent

3. **Configure the VPN gateway** with the tenant, audience, and issuer values

### RADIUS Authentication

RADIUS authentication allows integration with existing authentication systems like MFA servers, NPS (Network Policy Server), or third-party identity providers.

#### Bicep Template

```bicep
param radiusServerAddress string
param radiusServerSecret string
param radiusServerPort int = 1812

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = {
  // ... other properties
  properties: {
    // ... other properties
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          vpnClientAddressPoolPrefix
        ]
      }
      radiusServerAddress: radiusServerAddress
      radiusServerSecret: radiusServerSecret
      radiusServerPort: radiusServerPort
    }
  }
}
```

#### RADIUS Server Setup Considerations

- Ensure network connectivity between the VPN Gateway and RADIUS server
- Configure appropriate authentication policies on your RADIUS server
- Consider implementing RADIUS server redundancy for high availability

## Custom Client Configurations

## Split Tunneling Configuration

Split tunneling for the VPN Gateway is not directly configurable through the Bicep template. Instead, it is configured through one of these methods:

1. **Post-deployment configuration**: After deploying the VPN Gateway, download the VPN client configuration package and modify it to enable split tunneling.

2. **Custom route tables**: Configure route tables that only route traffic destined for the VNet address space through the VPN tunnel.

### PowerShell Example for Post-Deployment Configuration

```powershell
# Download VPN client configuration package
$ResourceGroupName = "dev-saf-rg-homelab"
$GatewayName = "dev-saf-vpng-homelab"
$ProfileName = "VpnClientProfile.zip"

$vpnClientPackage = Get-AzVpnClientPackage -ResourceGroupName $ResourceGroupName -VirtualNetworkGatewayName $GatewayName -ProcessorArchitecture "Amd64"
Invoke-WebRequest -Uri $vpnClientPackage.VpnProfileSasUrl -OutFile $ProfileName

# Extract, modify for split tunneling, and distribute to clients
```

### Client Configuration

Instructions for configuring split tunneling on client devices:

- **Windows**: Modify the VPN connection properties to use only remote networks
- **macOS**: Configure the VPN connection to only route specific subnets
- **Mobile devices**: Use the Azure VPN Client app which supports split tunneling configuration

### Custom DNS Servers

Configure custom DNS servers for VPN clients to use when connected, enabling name resolution for internal resources.

```bicep
param dnsServers array = [
  '10.0.0.4',
  '10.0.0.5'
]

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = {
  // ... other properties
  properties: {
    // ... other properties
    vpnClientConfiguration: {
      // ... other configurations
      dnsServers: dnsServers
    }
  }
}
```

#### DNS Configuration Best Practices

- Use Azure DNS Private Zones for seamless name resolution
- Consider implementing conditional forwarders for hybrid environments
- Ensure DNS servers are highly available
- Test name resolution for both internal and external domains

### Client Protocols

Specify which VPN protocols clients can use to connect, balancing security, compatibility, and performance requirements.

```bicep
param vpnClientProtocols array = [
  'OpenVPN',
  'IkeV2',
  'SSTP'
]

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = {
  // ... other properties
  properties: {
    // ... other properties
    vpnClientConfiguration: {
      // ... other configurations
      vpnClientProtocols: vpnClientProtocols
    }
  }
}
```

#### Available Protocols Comparison

| Protocol    | Platforms                         | Firewall Traversal       | Security  | Performance |
| ----------- | --------------------------------- | ------------------------ | --------- | ----------- |
| **SSTP**    | Windows only                      | Excellent (uses TCP 443) | Good      | Moderate    |
| **IkeV2**   | Windows, Mac, Linux, iOS, Android | Good                     | Excellent | Good        |
| **OpenVPN** | Windows, Mac, Linux, iOS, Android | Very Good (TCP/UDP 443)  | Excellent | Good        |

### Custom Routes

Configure custom routes to be pushed to VPN clients, enabling access to networks beyond the immediate VNet.

```bicep
param customRoutes array = [
  '10.1.0.0/24',
  '10.2.0.0/24'
]

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = {
  // ... other properties
  properties: {
    // ... other properties
    vpnClientConfiguration: {
      // ... other configurations
      customRoutes: {
        addressPrefixes: customRoutes
      }
    }
  }
}
```

#### Use Cases for Custom Routes

- Access to peered VNets
- Access to on-premises networks connected via ExpressRoute or S2S VPN
- Segmented access to specific subnets within the VNet

## Deployment Examples

### Certificate Authentication with Custom DNS

```bicep
// Parameters
param rootCertData string
param rootCertName string = 'P2SRootCert'
param vpnClientAddressPoolPrefix string = '172.16.0.0/24'
param dnsServers array = ['10.0.0.4']

// VPN Gateway resource
resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = {
  name: gatewayName
  location: location
  properties: {
    // ... other properties
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          vpnClientAddressPoolPrefix
        ]
      }
      vpnClientRootCertificates: [
        {
          name: rootCertName
          properties: {
            publicCertData: rootCertData
          }
        }
      ]
      dnsServers: dnsServers
    }
  }
}
```

### Azure AD Authentication with Custom DNS and Routes

```bicep
// Parameters
param tenantId string
param vpnClientAddressPoolPrefix string = '172.16.0.0/24'
param dnsServers array = ['10.0.0.4', '10.0.0.5']
param customRoutes array = ['10.1.0.0/24', '10.2.0.0/24']

// Variables
var audienceId = '41b23e61-6c1e-4545-b367-cd054e0ed4b4'
var issuerId = 'https://sts.windows.net/${tenantId}/'

// VPN Gateway resource
resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = {
  name: gatewayName
  location: location
  properties: {
    // ... other properties
    sku: {
      name: 'VpnGw1'  // Minimum SKU for Azure AD auth
      tier: 'VpnGw1'
    }
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          vpnClientAddressPoolPrefix
        ]
      }
      aadTenant: issuerId
      aadAudience: audienceId
      aadIssuer: issuerId
      vpnClientProtocols: [
        'OpenVPN'
      ]
      dnsServers: dnsServers
      customRoutes: {
        addressPrefixes: customRoutes
      }
    }
  }
}
```

## Troubleshooting

### Common Issues and Solutions

1. **VPN Client Connection Failures**
   - Verify client configuration is correctly downloaded and installed
   - Check client logs for specific error messages
   - Ensure client device has the appropriate certificates installed (for certificate auth)
   - Verify user has appropriate permissions (for Azure AD auth)

2. **"VpnClientAddressPoolNotSpecified" Error**
   - Ensure the VPN client address pool is configured in the gateway properties
   - Verify the address pool doesn't overlap with VNet address space

3. **Name Resolution Issues**
   - Verify DNS servers are correctly configured in the VPN client configuration
   - Check DNS server availability and routing from the VPN gateway
   - Test name resolution using nslookup or dig from connected clients

4. **Split Tunneling Not Working as Expected**
   - Note: Split tunneling is configured client-side, not at the gateway level
   - Check client-side routing table when connected
   - Verify VPN client configuration allows split tunneling
   - Ensure custom routes are correctly configured if needed

### Diagnostic Commands

```powershell
# Check VPN Gateway configuration
Get-AzVirtualNetworkGateway -Name "YourGatewayName" -ResourceGroupName "YourResourceGroup" | Select-Object -ExpandProperty VpnClientConfiguration

# Generate VPN client configuration package
$profile = New-AzVpnClientConfiguration -ResourceGroupName "YourResourceGroup" -Name "YourGatewayName" -AuthenticationMethod "EapTls"
$profile.VPNProfileSASUrl

# Test connectivity from client
Test-NetConnection -ComputerName "internal-resource.yourdomain.com" -Port 443
```

## Security Best Practices

1. **Authentication**
   - Use Azure AD authentication when possible for centralized identity management
   - Implement multi-factor authentication for VPN connections
   - Rotate certificates regularly if using certificate authentication

2. **Network Security**
   - Implement just-in-time access for VPN connections
   - Use Network Security Groups to restrict traffic within the VNet
   - Consider implementing Azure Firewall for traffic inspection

3. **Monitoring and Auditing**
   - Enable diagnostic logging for the VPN gateway
   - Set up alerts for unusual connection patterns
   - Regularly review VPN connection logs

4. **Client Security**
   - Ensure client devices meet security requirements before allowing connections
   - Consider implementing Conditional Access policies with Azure AD authentication
   - Deploy VPN client configurations through a secure channel

## Additional Resources

- [Azure VPN Gateway Documentation](https://docs.microsoft.com/en-us/azure/vpn-gateway/)
- [Point-to-Site VPN Configuration](https://docs.microsoft.com/en-us/azure/vpn-gateway/point-to-site-about)
- [Azure AD Integration with VPN](https://docs.microsoft.com/en-us/azure/vpn-gateway/openvpn-azure-ad-tenant)
- [Troubleshooting VPN Connections](https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-troubleshoot-point-to-site-connection-problems)
