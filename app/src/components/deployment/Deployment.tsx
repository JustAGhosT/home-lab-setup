import React, { useState } from 'react';
import MainLayout from '../layout/MainLayout';
import { invoke } from '../../utils/invoke';
import { DeploymentCommands, GatewayCommands, AzureCommands } from '../../constants/commands';

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

  const executeCommand = async (command: string, description: string): Promise<void> => {
    setIsDeploying(true);
    setActiveOperation(description);
    setLogs('');

    try {
      const result = await invoke('pwsh', ['-Command', command]);
      setLogs(result || 'Command executed successfully with no output');
    } catch (error) {
      // Bug fix: Better error formatting and logging
      const errorMessage = error instanceof Error 
        ? `Error: ${error.message}` 
        : `Error: ${String(error)}`;
      setLogs(errorMessage);
      console.error(`Failed to execute ${description}:`, error);
    } finally {
      setIsDeploying(false);
      setActiveOperation('');
    }
  };

  const handleDeployFull = async (): Promise<void> => {
    // Bug fix: Wrap in try-catch to prevent unhandled promise rejections
    try {
      // Code improvement: Use centralized command constants
      await executeCommand(
        DeploymentCommands.deployFull(),
        'Deploying Full Infrastructure'
      );
    } catch (error) {
      console.error('Unhandled error in handleDeployFull:', error);
    }
  };

  const handleDeployNetwork = async (): Promise<void> => {
    try {
      await executeCommand(
        DeploymentCommands.deployNetwork(),
        'Deploying Network Only'
      );
    } catch (error) {
      console.error('Unhandled error in handleDeployNetwork:', error);
    }
  };

  const handleDeployVpnGateway = async (): Promise<void> => {
    try {
      await executeCommand(
        DeploymentCommands.deployVpnGateway(),
        'Deploying VPN Gateway (This may take 30-45 minutes)'
      );
    } catch (error) {
      console.error('Unhandled error in handleDeployVpnGateway:', error);
    }
  };

  const handleDeployNatGateway = async (): Promise<void> => {
    try {
      await executeCommand(
        DeploymentCommands.deployNatGateway(),
        'Deploying NAT Gateway'
      );
    } catch (error) {
      console.error('Unhandled error in handleDeployNatGateway:', error);
    }
  };

  const handleCheckStatus = async (): Promise<void> => {
    setIsDeploying(true);
    setActiveOperation('Checking Deployment Status');
    setLogs('');

    try {
      const result = await invoke('pwsh', [
        '-Command',
        AzureCommands.getDeploymentStatus()
      ]);
      
      // Bug fix: Validate result before parsing
      if (result && result.trim() !== '') {
        const deploymentStatus = JSON.parse(result);
        setStatus(deploymentStatus);
        setLogs('Deployment status retrieved successfully');
      } else {
        setLogs('Warning: No deployment status returned');
      }
    } catch (error) {
      const errorMessage = error instanceof Error 
        ? `Error: ${error.message}` 
        : `Error: ${String(error)}`;
      setLogs(errorMessage);
      console.error('Failed to check deployment status:', error);
    } finally {
      setIsDeploying(false);
      setActiveOperation('');
    }
  };

  const handleEnableVpnGateway = async (): Promise<void> => {
    try {
      await executeCommand(
        GatewayCommands.enableVpn(),
        'Enabling VPN Gateway'
      );
    } catch (error) {
      console.error('Unhandled error in handleEnableVpnGateway:', error);
    }
  };

  const handleDisableVpnGateway = async (): Promise<void> => {
    try {
      await executeCommand(
        GatewayCommands.disableVpn(),
        'Disabling VPN Gateway'
      );
    } catch (error) {
      console.error('Unhandled error in handleDisableVpnGateway:', error);
    }
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
