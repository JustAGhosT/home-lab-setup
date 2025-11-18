import React, { useState, useEffect } from 'react';
import { invoke } from '../../utils/invoke';
import { ClientCommands } from '../../constants/commands';
import toast from 'react-hot-toast';

interface ConnectionStatus {
  isConnected: boolean;
  connectionName: string;
  serverAddress: string;
  connectedSince?: string;
}

const VpnClient: React.FC = () => {
  const [connectionStatus, setConnectionStatus] = useState<ConnectionStatus | null>(null);
  const [logs, setLogs] = useState<string>('');
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [activeOperation, setActiveOperation] = useState<string>('');
  const [error, setError] = useState<string | null>(null);

  const executeCommand = async (command: string, description: string) => {
    setIsLoading(true);
    setActiveOperation(description);
    setLogs('');
    setError(null);

    try {
      const result = await invoke('pwsh', ['-Command', command]);
      setLogs(result || 'Command executed successfully with no output.');
      toast.success(`${description} completed successfully!`);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : String(err);
      setError(`Error during ${description}: ${errorMessage}`);
      setLogs(`Error: ${errorMessage}`);
      toast.error(`Error during ${description}: ${errorMessage}`);
      console.error(`Failed to execute ${description}:`, err);
    } finally {
      setIsLoading(false);
      setActiveOperation('');
    }
  };

  useEffect(() => {
    handleCheckStatus();
  }, []);

  const handleAddComputer = async () => {
    await executeCommand(ClientCommands.addComputerToVpn(), 'Adding Computer to VPN');
  };

  const handleConnect = async () => {
    await executeCommand(ClientCommands.connectToVpn(), 'Connecting to VPN');
    handleCheckStatus();
  };

  const handleDisconnect = async () => {
    await executeCommand(ClientCommands.disconnectFromVpn(), 'Disconnecting from VPN');
    handleCheckStatus();
  };

  const handleCheckStatus = async () => {
    setIsLoading(true);
    setActiveOperation('Checking Connection Status');
    setLogs('');
    setError(null);

    try {
      const result = await invoke('pwsh', ['-Command', ClientCommands.getVpnConnectionStatus()]);
      const status = JSON.parse(result);
      setConnectionStatus(status);
      setLogs('Connection status retrieved successfully');
      toast.success('Connection status updated!');
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : String(err);
      setError(`Error checking status: ${errorMessage}`);
      setLogs(`Error: ${errorMessage}`);
      toast.error(`Error checking status: ${errorMessage}`);
    } finally {
      setIsLoading(false);
      setActiveOperation('');
    }
  };

  return (
    <div className="space-y-6">
      <div className="bg-white shadow-md rounded p-6">
        <h2 className="text-xl font-semibold mb-4">VPN Client Management</h2>
        <p className="text-gray-600 mb-6">
          Manage VPN client connections and computer configuration
        </p>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <button
            onClick={handleAddComputer}
            disabled={isLoading}
            className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            Add Computer
          </button>
          
          <button
            onClick={handleConnect}
            disabled={isLoading}
            className="bg-green-500 hover:bg-green-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            Connect
          </button>
          
          <button
            onClick={handleDisconnect}
            disabled={isLoading}
            className="bg-red-500 hover:bg-red-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            Disconnect
          </button>
          
          <button
            onClick={handleCheckStatus}
            disabled={isLoading}
            className="bg-purple-500 hover:bg-purple-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            Refresh Status
          </button>
        </div>

        {error && !isLoading && (
            <div className="mb-4 p-4 bg-red-50 border border-red-300 text-red-800 rounded-lg">
                <h3 className="font-semibold mb-2">⚠️ VPN Client Error</h3>
                <p className="text-sm">{error}</p>
            </div>
        )}

        {isLoading && (
            <div className="flex items-center justify-center p-4 bg-blue-50 border border-blue-200 rounded-lg">
                <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500"></div>
                <p className="ml-4 text-blue-800 font-semibold">In Progress: {activeOperation}...</p>
            </div>
        )}

        {!isLoading && connectionStatus && (
          <div className={`mb-4 p-4 rounded border ${
            connectionStatus.isConnected 
              ? 'bg-green-50 border-green-200' 
              : 'bg-gray-50 border-gray-200'
          }`}>
            <h3 className="text-lg font-medium mb-3">Connection Status</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div>
                <span className="font-semibold">Status:</span>{' '}
                <span className={`px-2 py-1 rounded text-xs font-semibold ${
                  connectionStatus.isConnected 
                    ? 'bg-green-200 text-green-800' 
                    : 'bg-gray-200 text-gray-800'
                }`}>
                  {connectionStatus.isConnected ? 'Connected' : 'Disconnected'}
                </span>
              </div>
              <div>
                <span className="font-semibold">Connection:</span> {connectionStatus.connectionName || 'N/A'}
              </div>
              <div>
                <span className="font-semibold">Server:</span> {connectionStatus.serverAddress || 'N/A'}
              </div>
              {connectionStatus.connectedSince && (
                <div>
                  <span className="font-semibold">Connected Since:</span> {connectionStatus.connectedSince}
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
        <h3 className="font-semibold text-blue-900 mb-2">💡 Quick Tips</h3>
        <ul className="list-disc list-inside text-blue-800 space-y-1">
          <li>Ensure VPN certificates are properly installed before connecting</li>
          <li>Use "Add Computer" to register a new device for VPN access</li>
          <li>Check connection status regularly to verify secure connectivity</li>
          <li>Disconnect when not in use to save resources</li>
        </ul>
      </div>
    </div>
  );
};

export default VpnClient;
