@description('Location for all resources.')
param location string = 'southafricanorth'

@description('Environment prefix for resources.')
param env string = 'dev'

@description('Location abbreviation for resources.')
param loc string = 'saf'

@description('Project name for resources.')
param project string = 'homelab'

@description('Address space for the virtual network.')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Address prefix for the default subnet.')
param defaultSubnetPrefix string = '10.0.0.0/24'

@description('Address prefix for the application subnet.')
param appSubnetPrefix string = '10.0.1.0/24'

@description('Address prefix for the database subnet.')
param dbSubnetPrefix string = '10.0.2.0/24'

@description('Whether to enable NAT Gateway')
param enableNatGateway bool = false

@description('Whether to enable VPN Gateway')
param enableVpnGateway bool = false

// Variables for resource naming
var prefix = '${env}-${loc}'
var vnetName = '${prefix}-vnet-${project}'
var defaultSubnetName = '${prefix}-snet-default-${project}'
var appSubnetName = '${prefix}-snet-app-${project}'
var dbSubnetName = '${prefix}-snet-db-${project}'
var nsgDefaultName = '${prefix}-nsg-default-${project}'
var nsgAppName = '${prefix}-nsg-app-${project}'
var nsgDbName = '${prefix}-nsg-db-${project}'

// Network Security Group for Default Subnet
resource nsgDefault 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: nsgDefaultName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSSH'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '22'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowRDP'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '3389'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Network Security Group for App Subnet
resource nsgApp 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: nsgAppName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHTTP'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '80'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Network Security Group for DB Subnet
resource nsgDb 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: nsgDbName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSQLServer'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: appSubnetPrefix
          destinationPortRange: '1433'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowMySQL'
        properties: {
          priority: 1001
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: appSubnetPrefix
          destinationPortRange: '3306'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: defaultSubnetName
        properties: {
          addressPrefix: defaultSubnetPrefix
          networkSecurityGroup: {
            id: nsgDefault.id
          }
        }
      }
      {
        name: appSubnetName
        properties: {
          addressPrefix: appSubnetPrefix
          networkSecurityGroup: {
            id: nsgApp.id
          }
        }
      }
      {
        name: dbSubnetName
        properties: {
          addressPrefix: dbSubnetPrefix
          networkSecurityGroup: {
            id: nsgDb.id
          }
        }
      }
    ]
  }
}

// Call the nat-gateway.bicep script
module natGateway 'nat-gateway.bicep' = if (enableNatGateway) {
  name: 'natGateway'
  params: {
    location: location
    env: env
    loc: loc
    project: project
    existingVnetName: vnetName
    subnetNames: [
      defaultSubnetName
      appSubnetName
    ]
    enableNatGateway: true
  }
  dependsOn: [
    vnet // Ensure the VNET exists before trying to reference it
  ]
}

// Call the VPN Gateway bicep script
module vpnGateway 'vpn-gateway.bicep' = if (enableVpnGateway) {
  name: 'vpnGateway'
  params: {
    location: location
    env: env
    loc: loc
    project: project
    existingVnetName: vnetName
  }
  dependsOn: [
    vnet // Ensure the VNET exists before trying to reference it
  ]
}

// Outputs
output virtualNetworkName string = vnet.name
output virtualNetworkId string = vnet.id
output defaultSubnetName string = defaultSubnetName
output defaultSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, defaultSubnetName)
output appSubnetName string = appSubnetName
output appSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, appSubnetName)
output dbSubnetName string = dbSubnetName
output dbSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, dbSubnetName)
output vpnGatewayName string = enableVpnGateway ? vpnGateway.outputs.vpnGatewayName : ''
output natGatewayName string = enableNatGateway ? natGateway.outputs.natGatewayName : ''
