// Azure NAT Gateway Setup for Home Lab

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

@description('Names of subnets to associate with the NAT Gateway.')
param subnetNames array

@description('Whether to initially enable the NAT Gateway by associating it with subnets.')
param enableNatGateway bool = false

// Variables for resource naming
var prefix = '${env}-${loc}'
var natGatewayName = '${prefix}-ng-${project}'
var natGatewayPublicIPName = '${prefix}-pip-ng-${project}'

// Public IP for NAT Gateway
resource natGatewayPublicIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: natGatewayPublicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// NAT Gateway
resource natGateway 'Microsoft.Network/natGateways@2021-05-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: natGatewayPublicIP.id
      }
    ]
    idleTimeoutInMinutes: 4
  }
}

// Get existing subnets to update
module subnetInfo 'modules/get-subnet-info.bicep' = [for subnetName in subnetNames: if(enableNatGateway) {
  name: 'get-subnet-${subnetName}'
  params: {
    vnetName: existingVnetName
    subnetName: subnetName
  }
}]

// Update subnets with NAT Gateway
resource updatedSubnets 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = [for (subnetName, i) in subnetNames: if(enableNatGateway) {
  name: '${existingVnetName}/${subnetName}'
  properties: {
    // Keep all existing subnet properties
    addressPrefix: reference(resourceId('Microsoft.Network/virtualNetworks/subnets', existingVnetName, subnetName)).addressPrefix
    
    // Add NAT Gateway
    natGateway: {
      id: natGateway.id
    }
  }
  dependsOn: [
    subnetInfo
  ]
}]

// Outputs
output natGatewayId string = natGateway.id
output natGatewayPublicIpId string = natGatewayPublicIP.id
output natGatewayName string = natGatewayName
