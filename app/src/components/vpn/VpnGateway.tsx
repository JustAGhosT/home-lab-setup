import React, { useState } from 'react';
import { invoke } from '../../utils/invoke';

interface GatewayStatus {
  name: string;
  provisioningState: string;
  vpnClientAddressPool: string;
  vpnType: string;
  sku: string;
}

const VpnGateway: React.FC = () => {
  const [status, setStatus] = useState<GatewayStatus | null>(null);
  const [logs, setLogs] = useState<string>('');
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [activeOperation, setActiveOperation] = useState<string>('');

  const executeCommand = async (command: string, description: string) => {
    setIsLoading(true);
    setActiveOperation(description);
    setLogs('');
    
    try {
      const result = await invoke('pwsh', ['-Command', command]);
      setLogs(result);
    } catch (error) {
      if (error instanceof Error) {
        setLogs(`Error: ${error.message}`);
      } else {
        setLogs(`Error: ${String(error)}`);
      }
    } finally {
      setIsLoading(false);
      setActiveOperation('');
    }
  };

  const handleCheckStatus = async () => {
    setIsLoading(true);
    setActiveOperation('Checking Gateway Status');
    setLogs('');
    
    try {
      const result = await invoke('pwsh', [
        '-Command',
        'Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; Get-VpnGatewayStatus | ConvertTo-Json'
      ]);
      const gatewayStatus = JSON.parse(result);
      setStatus(gatewayStatus);
      setLogs('Gateway status retrieved successfully');
    } catch (error) {
      if (error instanceof Error) {
        setLogs(`Error: ${error.message}`);
      } else {
        setLogs(`Error: ${String(error)}`);
      }
    } finally {
      setIsLoading(false);
      setActiveOperation('');
    }
  };

  const handleGenerateClientConfig = async () => {
    await executeCommand(
      'Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; New-VpnClientConfiguration',
      'Generating VPN Client Configuration'
    );
  };

  const handleUploadCertificate = async () => {
    await executeCommand(
      'Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; Add-VpnGatewayCertificate',
      'Uploading Certificate to Gateway'
    );
  };

  const handleRemoveCertificate = async () => {
    await executeCommand(
      'Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; Remove-VpnGatewayCertificate',
      'Removing Certificate from Gateway'
    );
  };

  const handleConfigureSplitTunneling = async () => {
    await executeCommand(
      'Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; Set-VpnSplitTunneling',
      'Configuring VPN Split Tunneling'
    );
  };

  return (
    <div className="space-y-6">
      <div className="bg-white shadow-md rounded p-6">
        <h2 className="text-xl font-semibold mb-4">VPN Gateway Management</h2>
        <p className="text-gray-600 mb-6">
          Manage your Azure VPN Gateway configuration and settings
        </p>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
          <button
            onClick={handleCheckStatus}
            disabled={isLoading}
            className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            Check Status
          </button>
          
          <button
            onClick={handleGenerateClientConfig}
            disabled={isLoading}
            className="bg-green-500 hover:bg-green-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            Generate Client Config
          </button>
          
          <button
            onClick={handleUploadCertificate}
            disabled={isLoading}
            className="bg-purple-500 hover:bg-purple-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            Upload Certificate
          </button>
          
          <button
            onClick={handleRemoveCertificate}
            disabled={isLoading}
            className="bg-red-500 hover:bg-red-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            Remove Certificate
          </button>
          
          <button
            onClick={handleConfigureSplitTunneling}
            disabled={isLoading}
            className="bg-orange-500 hover:bg-orange-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            Configure Split Tunneling
          </button>
        </div>

        {isLoading && (
          <div className="mb-4 p-4 bg-blue-100 border border-blue-300 rounded">
            <p className="text-blue-800">
              <span className="font-semibold">In Progress:</span> {activeOperation}...
            </p>
          </div>
        )}

        {status && (
          <div className="mb-4 p-4 bg-green-50 border border-green-200 rounded">
            <h3 className="text-lg font-medium mb-3">Gateway Status</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div>
                <span className="font-semibold">Name:</span> {status.name}
              </div>
              <div>
                <span className="font-semibold">State:</span>{' '}
                <span className={`px-2 py-1 rounded text-xs font-semibold ${
                  status.provisioningState === 'Succeeded' 
                    ? 'bg-green-200 text-green-800' 
                    : 'bg-yellow-200 text-yellow-800'
                }`}>
                  {status.provisioningState}
                </span>
              </div>
              <div>
                <span className="font-semibold">Address Pool:</span> {status.vpnClientAddressPool}
              </div>
              <div>
                <span className="font-semibold">VPN Type:</span> {status.vpnType}
              </div>
              <div>
                <span className="font-semibold">SKU:</span> {status.sku}
              </div>
            </div>
          </div>
        )}

        {logs && (
          <div>
            <h3 className="text-lg font-medium mb-2">Output:</h3>
            <pre className="bg-gray-900 text-green-400 p-4 rounded overflow-x-auto max-h-96">
              {logs}
            </pre>
          </div>
        )}
      </div>
    </div>
  );
};

export default VpnGateway;
