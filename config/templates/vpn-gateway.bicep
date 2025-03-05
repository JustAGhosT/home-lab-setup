// Azure VPN Gateway Setup for Home Lab

// Parameters
@description('Location for all resources.')
param location string = 'southafricanorth'

@description('Environment prefix for resources.')
param env string = 'dev'

@description('Location abbreviation for resources.')
param loc string = 'saf'

@description('Project name for resources.')
param project string = 'homelab'

@description('Name of your existing virtual network.')
param existingVnetName string

@description('Name for the gateway subnet.')
param gatewaySubnetName string = 'GatewaySubnet'

@description('Address prefix for the gateway subnet.')
param gatewaySubnetPrefix string = '10.0.255.0/27'

@description('SKU for the VPN Gateway.')
@allowed([
  'Basic'
  'VpnGw1'
  'VpnGw2'
  'VpnGw3'
])
param gatewaySku string = 'Basic'

@description('Type of VPN Gateway.')
@allowed([
  'Vpn'
  'ExpressRoute'
])
param gatewayType string = 'Vpn'

@description('VPN type.')
@allowed([
  'RouteBased'
  'PolicyBased'
])
param vpnType string = 'RouteBased'

@description('Whether to deploy the VPN Gateway.')
param deployVpnGateway bool = false

@description('Address space for VPN clients (Point-to-Site connections).')
param vpnClientAddressPoolPrefix string = '172.16.0.0/24'

@description('Enable split tunneling for VPN clients. When true, only traffic to VNet addresses goes through VPN.')
param enableSplitTunneling bool = true

// Variables for resource naming
var prefix = '${env}-${loc}'
var gatewayName = '${prefix}-vpng-${project}'
var gatewayPublicIPName = '${prefix}-pip-vpng-${project}'

// Reference the existing virtual network
resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: existingVnetName
}

// Add the gateway subnet to the existing virtual network
// Note: We always create the subnet as it doesn't incur costs
resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  parent: vnet
  name: gatewaySubnetName
  properties: {
    addressPrefix: gatewaySubnetPrefix
  }
}

// Public IP for the VPN Gateway - only deploy if VPN Gateway is enabled
resource gatewayPublicIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = if(deployVpnGateway) {
  name: gatewayPublicIPName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

// VPN Gateway - only deploy if enabled
resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' = if(deployVpnGateway) {
  name: gatewayName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnet.id
          }
          publicIPAddress: {
            id: gatewayPublicIP.id
          }
        }
      }
    ]
    gatewayType: gatewayType
    vpnType: vpnType
    enableBgp: false
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          vpnClientAddressPoolPrefix
        ]
      }
      splitTunnel: enableSplitTunneling
    }
  }
}

// Outputs - handle conditional deployment
output vpnGatewayId string = deployVpnGateway ? vpnGateway.id : ''
output vpnGatewayPipId string = deployVpnGateway ? gatewayPublicIP.id : ''
