import React, { useState } from 'react';
import MainLayout from '../layout/MainLayout';
import { invoke } from '../../utils/invoke';

interface DeploymentStatus {
  network: string;
  vpnGateway: string;
  natGateway: string;
  lastDeployment?: string;
}

const Deployment: React.FC = () => {
  const [logs, setLogs] = useState<string>('');
  const [isDeploying, setIsDeploying] = useState<boolean>(false);
  const [activeOperation, setActiveOperation] = useState<string>('');
  const [status, setStatus] = useState<DeploymentStatus | null>(null);

  const executeCommand = async (command: string, description: string) => {
    setIsDeploying(true);
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
      setIsDeploying(false);
      setActiveOperation('');
    }
  };

  const handleDeployFull = async () => {
    await executeCommand(
      'Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; Deploy-FullInfrastructure',
      'Deploying Full Infrastructure'
    );
  };

  const handleDeployNetwork = async () => {
    await executeCommand(
      'Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; Deploy-NetworkOnly',
      'Deploying Network Only'
    );
  };

  const handleDeployVpnGateway = async () => {
    await executeCommand(
      'Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; Deploy-VpnGateway',
      'Deploying VPN Gateway (This may take 30-45 minutes)'
    );
  };

  const handleDeployNatGateway = async () => {
    await executeCommand(
      'Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; Deploy-NatGateway',
      'Deploying NAT Gateway'
    );
  };

  const handleCheckStatus = async () => {
    setIsDeploying(true);
    setActiveOperation('Checking Deployment Status');
    setLogs('');

    try {
      const result = await invoke('pwsh', [
        '-Command',
        'Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; Get-DeploymentStatus | ConvertTo-Json'
      ]);
      const deploymentStatus = JSON.parse(result);
      setStatus(deploymentStatus);
      setLogs('Deployment status retrieved successfully');
    } catch (error) {
      if (error instanceof Error) {
        setLogs(`Error: ${error.message}`);
      } else {
        setLogs(`Error: ${String(error)}`);
      }
    } finally {
      setIsDeploying(false);
      setActiveOperation('');
    }
  };

  const handleEnableVpnGateway = async () => {
    await executeCommand(
      'Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; Enable-VpnGateway',
      'Enabling VPN Gateway'
    );
  };

  const handleDisableVpnGateway = async () => {
    await executeCommand(
      'Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; Disable-VpnGateway',
      'Disabling VPN Gateway'
    );
  };

  return (
    <MainLayout title="Deployment">
      <div className="deployment space-y-6">
        <div className="bg-white shadow-md rounded p-6">
          <h2 className="text-xl font-semibold mb-4">Azure Infrastructure Deployment</h2>
          <p className="text-gray-600 mb-6">
            Deploy and manage your Azure HomeLab infrastructure components
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
            <button
              onClick={handleDeployFull}
              disabled={isDeploying}
              className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              Deploy Full Infrastructure
            </button>

            <button
              onClick={handleDeployNetwork}
              disabled={isDeploying}
              className="bg-green-500 hover:bg-green-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              Deploy Network Only
            </button>

            <button
              onClick={handleDeployVpnGateway}
              disabled={isDeploying}
              className="bg-purple-500 hover:bg-purple-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              Deploy VPN Gateway
            </button>

            <button
              onClick={handleDeployNatGateway}
              disabled={isDeploying}
              className="bg-orange-500 hover:bg-orange-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              Deploy NAT Gateway
            </button>

            <button
              onClick={handleCheckStatus}
              disabled={isDeploying}
              className="bg-indigo-500 hover:bg-indigo-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              Check Status
            </button>
          </div>

          <div className="border-t pt-4 mb-6">
            <h3 className="text-lg font-medium mb-3">VPN Gateway Management</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <button
                onClick={handleEnableVpnGateway}
                disabled={isDeploying}
                className="bg-green-600 hover:bg-green-800 text-white font-bold py-2 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
              >
                Enable VPN Gateway
              </button>

              <button
                onClick={handleDisableVpnGateway}
                disabled={isDeploying}
                className="bg-red-600 hover:bg-red-800 text-white font-bold py-2 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
              >
                Disable VPN Gateway
              </button>
            </div>
          </div>

          {isDeploying && (
            <div className="mb-4 p-4 bg-blue-100 border border-blue-300 rounded">
              <p className="text-blue-800">
                <span className="font-semibold">In Progress:</span> {activeOperation}...
              </p>
              {activeOperation.includes('VPN Gateway') && (
                <p className="text-blue-600 text-sm mt-2">
                  Note: VPN Gateway deployment typically takes 30-45 minutes to complete.
                </p>
              )}
            </div>
          )}

          {status && (
            <div className="mb-4 p-4 bg-green-50 border border-green-200 rounded">
              <h3 className="text-lg font-medium mb-3">Deployment Status</h3>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                <div>
                  <span className="font-semibold">Network:</span>{' '}
                  <span className={`px-2 py-1 rounded text-xs font-semibold ${
                    status.network === 'Deployed' 
                      ? 'bg-green-200 text-green-800' 
                      : 'bg-gray-200 text-gray-800'
                  }`}>
                    {status.network}
                  </span>
                </div>
                <div>
                  <span className="font-semibold">VPN Gateway:</span>{' '}
                  <span className={`px-2 py-1 rounded text-xs font-semibold ${
                    status.vpnGateway === 'Deployed' 
                      ? 'bg-green-200 text-green-800' 
                      : 'bg-gray-200 text-gray-800'
                  }`}>
                    {status.vpnGateway}
                  </span>
                </div>
                <div>
                  <span className="font-semibold">NAT Gateway:</span>{' '}
                  <span className={`px-2 py-1 rounded text-xs font-semibold ${
                    status.natGateway === 'Deployed' 
                      ? 'bg-green-200 text-green-800' 
                      : 'bg-gray-200 text-gray-800'
                  }`}>
                    {status.natGateway}
                  </span>
                </div>
              </div>
              {status.lastDeployment && (
                <div className="mt-3">
                  <span className="font-semibold">Last Deployment:</span> {status.lastDeployment}
                </div>
              )}
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

        <div className="bg-yellow-50 border border-yellow-200 rounded p-4">
          <h3 className="font-semibold text-yellow-900 mb-2">⚠️ Important Notes</h3>
          <ul className="list-disc list-inside text-yellow-800 space-y-1">
            <li>VPN Gateway deployment can take 30-45 minutes to complete</li>
            <li>Ensure proper Azure credentials are configured before deployment</li>
            <li>Full infrastructure deployment includes VNet, subnets, VPN Gateway, and NAT Gateway</li>
            <li>Enable/Disable VPN Gateway to manage costs when not in use</li>
          </ul>
        </div>
      </div>
    </MainLayout>
  );
};

export default Deployment;
