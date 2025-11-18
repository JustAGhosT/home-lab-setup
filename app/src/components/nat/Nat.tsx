import React, { useState, useEffect } from 'react';
import MainLayout from '../layout/MainLayout';
import { GatewayCommands, DeploymentCommands } from '../../constants/commands';
import { useCommand } from '../../hooks/useCommand';
import { invoke } from '../../utils/invoke';
import toast from 'react-hot-toast';

interface NatGatewayStatus {
  name: string;
  provisioningState: string;
  publicIpAddress: string;
  associatedSubnets: string[];
  idleTimeoutInMinutes: number;
}

const Nat: React.FC = () => {
  const { logs, isLoading, error, executeCommand } = useCommand();
  const [activeOperation, setActiveOperation] = useState<string>('');
  const [status, setStatus] = useState<NatGatewayStatus | null>(null);

  useEffect(() => {
    handleCheckStatus();
  }, []);

  const handleCreate = async () => {
    await executeCommand(DeploymentCommands.deployNatGateway(), 'Creating NAT Gateway');
    handleCheckStatus();
  };

  const handleEnable = async () => {
    await executeCommand(GatewayCommands.enableNat(), 'Enabling NAT Gateway');
    handleCheckStatus();
  };

  const handleDisable = async () => {
    await executeCommand(GatewayCommands.disableNat(), 'Disabling NAT Gateway');
    handleCheckStatus();
  };

  const handleCheckStatus = async () => {
    setActiveOperation('Checking NAT Gateway Status');

    try {
      const result = await invoke('pwsh', ['-Command', GatewayCommands.getNatStatus()]);
      const natStatus = JSON.parse(result);
      setStatus(natStatus);
      toast.success('NAT Gateway status updated!');
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : String(err);
      toast.error(`Error checking status: ${errorMessage}`);
    } finally {
      setActiveOperation('');
    }
  };

  const handleDelete = async () => {
    if (window.confirm('Are you sure you want to delete the NAT Gateway? This action cannot be undone.')) {
      await executeCommand(DeploymentCommands.deleteNatGateway(), 'Deleting NAT Gateway');
      handleCheckStatus();
    }
  };

  return (
    <MainLayout title="NAT Gateway">
      <div className="nat space-y-6">
        <div className="bg-white shadow-md rounded p-6">
          <h2 className="text-xl font-semibold mb-4">NAT Gateway Management</h2>
          <p className="text-gray-600 mb-6">
            Manage Azure NAT Gateway for outbound internet connectivity. Enable when needed and disable to save costs.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
            <button
              onClick={handleCreate}
              disabled={isLoading}
              className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              Create NAT Gateway
            </button>

            <button
              onClick={handleEnable}
              disabled={isLoading}
              className="bg-green-500 hover:bg-green-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              Enable
            </button>

            <button
              onClick={handleDisable}
              disabled={isLoading}
              className="bg-orange-500 hover:bg-orange-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              Disable
            </button>

            <button
              onClick={handleCheckStatus}
              disabled={isLoading}
              className="bg-purple-500 hover:bg-purple-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              Refresh Status
            </button>

            <button
              onClick={handleDelete}
              disabled={isLoading}
              className="bg-red-500 hover:bg-red-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              Delete
            </button>
          </div>

          {error && !isLoading && (
            <div className="mb-4 p-4 bg-red-50 border border-red-300 text-red-800 rounded-lg">
                <h3 className="font-semibold mb-2">⚠️ NAT Gateway Error</h3>
                <p className="text-sm">{error}</p>
            </div>
          )}

          {isLoading && (
            <div className="flex items-center justify-center p-4 bg-blue-50 border border-blue-200 rounded-lg">
                <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500"></div>
                <p className="ml-4 text-blue-800 font-semibold">In Progress: {activeOperation}...</p>
            </div>
          )}

          {!isLoading && status && (
            <div className="mb-4 p-4 bg-green-50 border border-green-200 rounded">
              <h3 className="text-lg font-medium mb-3">NAT Gateway Status</h3>
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
                  <span className="font-semibold">Public IP:</span> {status.publicIpAddress}
                </div>
                <div>
                  <span className="font-semibold">Idle Timeout:</span> {status.idleTimeoutInMinutes} minutes
                </div>
                {status.associatedSubnets && status.associatedSubnets.length > 0 && (
                  <div className="col-span-2">
                    <span className="font-semibold">Associated Subnets:</span>
                    <ul className="list-disc list-inside ml-4 mt-1">
                      {status.associatedSubnets.map((subnet, index) => (
                        <li key={index} className="text-gray-700">{subnet}</li>
                      ))}
                    </ul>
                  </div>
                )}
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

        <div className="bg-blue-50 border border-blue-200 rounded p-4">
          <h3 className="font-semibold text-blue-900 mb-2">💡 Cost Management Tips</h3>
          <ul className="list-disc list-inside text-blue-800 space-y-1">
            <li>NAT Gateway costs approximately $32.40/month plus data processing fees</li>
            <li>Disable the gateway when not in use to save costs</li>
            <li>Each public IP associated with NAT Gateway adds ~$2.60/month</li>
            <li>Data processing charges are $0.045 per GB processed</li>
          </ul>
        </div>

        <div className="bg-yellow-50 border border-yellow-200 rounded p-4">
          <h3 className="font-semibold text-yellow-900 mb-2">⚠️ Important Notes</h3>
          <ul className="list-disc list-inside text-yellow-800 space-y-1">
            <li>NAT Gateway provides outbound internet connectivity for private subnets</li>
            <li>Deleting the NAT Gateway will remove outbound internet access</li>
            <li>Ensure VMs in associated subnets don't have public IPs when using NAT Gateway</li>
            <li>Changes may take a few minutes to propagate</li>
          </ul>
        </div>
      </div>
    </MainLayout>
  );
};

export default Nat;
