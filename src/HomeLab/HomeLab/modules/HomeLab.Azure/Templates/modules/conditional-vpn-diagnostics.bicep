@description('Name of the existing VPN gateway.')
param vpnGatewayName string

@description('Log Analytics Workspace ID.')
param workspaceId string

// Reference existing VPN Gateway
resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01' existing = {
  name: vpnGatewayName
}

// Configure diagnostic settings for VPN Gateway
resource vpnGatewayDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${vpnGatewayName}-diagnostics'
  scope: vpnGateway
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'GatewayDiagnosticLog'
        enabled: true
      }
      {
        category: 'TunnelDiagnosticLog'
        enabled: true
      }
      {
        category: 'RouteDiagnosticLog'
        enabled: true
      }
      {
        category: 'IKEDiagnosticLog'
        enabled: true
      }
      {
        category: 'P2SDiagnosticLog'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
