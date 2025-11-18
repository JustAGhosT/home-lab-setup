/**
 * PowerShell command constants for HomeLab operations
 * Centralizes all PowerShell commands to avoid duplication and make maintenance easier
 */

// Code improvement: Extract hard-coded module path into a constant
export const HOMELAB_MODULE_PATH = '/app/src/HomeLab/HomeLab/HomeLab.psd1';

/**
 * Generates a PowerShell command with module import
 * @param command - The PowerShell command to execute
 * @returns Complete PowerShell command string with module import
 */
export const createHomelabCommand = (command: string): string => {
  return `Import-Module ${HOMELAB_MODULE_PATH}; ${command}`;
};

/**
 * Azure connection and status commands
 */
export const AzureCommands = {
  getConnectionStatus: () => createHomelabCommand('Get-AzureConnectionStatus | ConvertTo-Json'),
  getResourceSummary: () => createHomelabCommand('Get-ResourceSummary | ConvertTo-Json'),
  getDeploymentStatus: () => createHomelabCommand('Get-DeploymentStatus | ConvertTo-Json'),
} as const;

/**
 * Infrastructure deployment commands
 */
export const DeploymentCommands = {
  deployFull: () => createHomelabCommand('Deploy-FullInfrastructure'),
  deployNetwork: () => createHomelabCommand('Deploy-NetworkOnly'),
  deployVpnGateway: () => createHomelabCommand('Deploy-VpnGateway'),
  deployNatGateway: () => createHomelabCommand('Deploy-NatGateway'),
  deleteNatGateway: () => createHomelabCommand('Remove-NatGateway -Force'),
} as const;

/**
 * Gateway management commands
 */
export const GatewayCommands = {
  enableVpn: () => createHomelabCommand('Enable-VpnGateway'),
  disableVpn: () => createHomelabCommand('Disable-VpnGateway'),
  enableNat: () => createHomelabCommand('Enable-NatGateway'),
  disableNat: () => createHomelabCommand('Disable-NatGateway'),
  getVpnStatus: () => createHomelabCommand('Get-VpnGatewayStatus | ConvertTo-Json'),
  getNatStatus: () => createHomelabCommand('Get-NatGatewayStatus | ConvertTo-Json'),
  generateClientConfig: () => createHomelabCommand('New-VpnClientConfiguration'),
  configureSplitTunneling: () => createHomelabCommand('Set-VpnSplitTunneling'),
} as const;

/**
 * DNS management commands
 */
export const DnsCommands = {
  createZone: (zoneName: string) => createHomelabCommand(`New-DnsZone -ZoneName "${zoneName}"`),
  addRecord: (zone: string, name: string, type: string, value: string) =>
    createHomelabCommand(`Add-DnsRecord -Zone "${zone}" -Name "${name}" -Type "${type}" -Value "${value}"`),
  listZones: () => createHomelabCommand('Get-DnsZones | ConvertTo-Json'),
  listRecords: (zoneName: string) => createHomelabCommand(`Get-DnsRecords -ZoneName "${zoneName}" | ConvertTo-Json`),
  deleteZone: (zoneName: string) => createHomelabCommand(`Remove-DnsZone -ZoneName "${zoneName}" -Force`),
} as const;

/**
 * Security and VPN certificate commands
 */
export const SecurityCommands = {
  createRootCert: () => createHomelabCommand('New-VpnRootCertificate'),
  createClientCert: () => createHomelabCommand('New-VpnClientCertificate'),
  addClientToRoot: () => createHomelabCommand('Add-VpnClientCertificateToRoot'),
  uploadToGateway: () => createHomelabCommand('Upload-VpnCertificateToGateway'),
  listCertificates: () => createHomelabCommand('Get-VpnCertificates | ConvertTo-Json'),
  addVpnGatewayCertificate: () => createHomelabCommand('Add-VpnGatewayCertificate'),
  removeVpnGatewayCertificate: () => createHomelabCommand('Remove-VpnGatewayCertificate'),
} as const;

/**
 * VPN client management commands
 */
export const ClientCommands = {
    addComputerToVpn: () => createHomelabCommand('Add-ComputerToVpn'),
    connectToVpn: () => createHomelabCommand('Connect-ToVpn'),
    disconnectFromVpn: () => createHomelabCommand('Disconnect-FromVpn'),
    getVpnConnectionStatus: () => createHomelabCommand('Get-VpnConnectionStatus | ConvertTo-Json'),
} as const;

/**
 * Operation timeouts (in milliseconds)
 */
export const OperationTimeouts = {
  short: 30000,    // 30 seconds - for quick operations
  medium: 120000,  // 2 minutes - for standard operations
  long: 900000,    // 15 minutes - for VPN gateway operations
  veryLong: 2700000, // 45 minutes - for full infrastructure deployment
} as const;

/**
 * Retry configuration
 */
export const RetryConfig = {
  maxAttempts: 3,
  initialDelay: 1000,  // 1 second
  backoffMultiplier: 2,
} as const;
