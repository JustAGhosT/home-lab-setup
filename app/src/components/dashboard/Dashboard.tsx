import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import MainLayout from '../layout/MainLayout';
import { invoke } from '../../utils/invoke';
import { AzureCommands } from '../../constants/commands';

interface AzureStatus {
  isConnected: boolean;
  subscriptionName?: string;
  tenantId?: string;
  accountName?: string;
}

interface ResourceSummary {
  vpnGateway: 'Active' | 'Inactive' | 'Not Deployed';
  natGateway: 'Active' | 'Inactive' | 'Not Deployed';
  virtualNetwork: 'Active' | 'Not Deployed';
  lastDeployment?: string;
}

const Dashboard: React.FC = () => {
  const [azureStatus, setAzureStatus] = useState<AzureStatus | null>(null);
  const [resourceSummary, setResourceSummary] = useState<ResourceSummary | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    setIsLoading(true);
    setError(null);
    setAzureStatus(null);
    setResourceSummary(null);

    try {
      const azureResult = await invoke('pwsh', [
        '-Command',
        AzureCommands.getConnectionStatus(),
      ]);

      if (azureResult && azureResult.trim()) {
        const parsedAzureStatus = JSON.parse(azureResult);
        if (
          parsedAzureStatus &&
          typeof parsedAzureStatus.isConnected === 'boolean'
        ) {
          setAzureStatus(parsedAzureStatus);
        } else {
          throw new Error('Invalid Azure status response format. The response from the PowerShell command was not as expected.');
        }
      } else {
        setAzureStatus({ isConnected: false }); // Assume disconnected if response is empty
      }

      const resourceResult = await invoke('pwsh', [
        '-Command',
        AzureCommands.getResourceSummary(),
      ]);

      if (resourceResult && resourceResult.trim()) {
        const parsedResourceSummary = JSON.parse(resourceResult);
        if (
          parsedResourceSummary &&
          typeof parsedResourceSummary.vpnGateway === 'string' &&
          typeof parsedResourceSummary.natGateway === 'string' &&
          typeof parsedResourceSummary.virtualNetwork === 'string'
        ) {
          setResourceSummary(parsedResourceSummary);
        } else {
            throw new Error('Invalid resource summary response format. The response from the PowerShell command was not as expected.');
        }
      } else {
          setResourceSummary(null); // Set to null if no resources are found or response is empty
      }

    } catch (err) {
      const errorMessage =
        err instanceof Error ? err.message : 'An unknown error occurred';
      console.error('Error loading dashboard data:', errorMessage);
      setError(`Failed to load dashboard data: ${errorMessage}`);
    } finally {
      setIsLoading(false);
    }
  };

  const quickActions = [
    { title: 'Deploy Infrastructure', icon: '🚀', link: '/deployment', color: 'bg-blue-500' },
    { title: 'VPN Management', icon: '🔐', link: '/vpn', color: 'bg-purple-500' },
    { title: 'NAT Gateway', icon: '🌐', link: '/nat', color: 'bg-green-500' },
    { title: 'Settings', icon: '⚙️', link: '/settings', color: 'bg-orange-500' },
  ];

  return (
    <MainLayout title="Dashboard">
      <div className="dashboard space-y-6">
        <div className="bg-gradient-to-r from-blue-500 to-purple-600 text-white shadow-lg rounded-lg p-6">
          <h2 className="text-2xl font-bold mb-2">Welcome to HomeLab Setup</h2>
          <p className="text-blue-100">
            Manage your Azure infrastructure, VPN, and NAT Gateway from this centralized dashboard
          </p>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-300 text-red-800 rounded-lg p-4">
            <h3 className="font-semibold mb-2">⚠️ Error Loading Dashboard</h3>
            <p className="text-sm">{error}</p>
            <button
              onClick={loadDashboardData}
              className="mt-3 px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition-colors"
            >
              Retry
            </button>
          </div>
        )}

        {isLoading ? (
          <div className="bg-white shadow-md rounded p-6 text-center">
            <p className="text-gray-600">Loading dashboard data...</p>
          </div>
        ) : (
          <>
            <div className="bg-white shadow-md rounded p-6">
              <h3 className="text-xl font-semibold mb-4">Azure Connection Status</h3>
              {azureStatus ? (
                <div className="space-y-3">
                  <div className="flex items-center">
                    <span className="font-semibold w-40">Connection:</span>
                    <span className={`px-3 py-1 rounded text-sm font-semibold ${
                      azureStatus.isConnected
                        ? 'bg-green-200 text-green-800'
                        : 'bg-red-200 text-red-800'
                    }`}>
                      {azureStatus.isConnected ? 'Connected ✓' : 'Disconnected ✗'}
                    </span>
                  </div>
                  {azureStatus.isConnected && (
                    <>
                      {azureStatus.accountName && (
                        <div className="flex items-center">
                          <span className="font-semibold w-40">Account:</span>
                          <span className="text-gray-700">{azureStatus.accountName}</span>
                        </div>
                      )}
                      {azureStatus.subscriptionName && (
                        <div className="flex items-center">
                          <span className="font-semibold w-40">Subscription:</span>
                          <span className="text-gray-700">{azureStatus.subscriptionName}</span>
                        </div>
                      )}
                      {azureStatus.tenantId && (
                        <div className="flex items-center">
                          <span className="font-semibold w-40">Tenant ID:</span>
                          <span className="text-gray-700 font-mono text-sm">{azureStatus.tenantId}</span>
                        </div>
                      )}
                    </>
                  )}
                  {!azureStatus.isConnected && (
                    <div className="mt-4 p-3 bg-yellow-50 border border-yellow-200 rounded">
                      <p className="text-yellow-800 text-sm">
                        Please configure Azure credentials in Settings to connect
                      </p>
                    </div>
                  )}
                </div>
              ) : (
                <p className="text-gray-500">Unable to retrieve Azure connection status</p>
              )}
            </div>

            <div className="bg-white shadow-md rounded p-6">
              <h3 className="text-xl font-semibold mb-4">Resource Summary</h3>
              {resourceSummary ? (
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="border rounded p-4">
                    <div className="flex items-center justify-between mb-2">
                      <span className="font-semibold">Virtual Network</span>
                      <span className="text-2xl">🌐</span>
                    </div>
                    <span className={`inline-block px-3 py-1 rounded text-sm font-semibold ${
                      resourceSummary.virtualNetwork === 'Active'
                        ? 'bg-green-200 text-green-800'
                        : 'bg-gray-200 text-gray-800'
                    }`}>
                      {resourceSummary.virtualNetwork}
                    </span>
                  </div>

                  <div className="border rounded p-4">
                    <div className="flex items-center justify-between mb-2">
                      <span className="font-semibold">VPN Gateway</span>
                      <span className="text-2xl">🔐</span>
                    </div>
                    <span className={`inline-block px-3 py-1 rounded text-sm font-semibold ${
                      resourceSummary.vpnGateway === 'Active'
                        ? 'bg-green-200 text-green-800'
                        : resourceSummary.vpnGateway === 'Inactive'
                        ? 'bg-orange-200 text-orange-800'
                        : 'bg-gray-200 text-gray-800'
                    }`}>
                      {resourceSummary.vpnGateway}
                    </span>
                  </div>

                  <div className="border rounded p-4">
                    <div className="flex items-center justify-between mb-2">
                      <span className="font-semibold">NAT Gateway</span>
                      <span className="text-2xl">🚪</span>
                    </div>
                    <span className={`inline-block px-3 py-1 rounded text-sm font-semibold ${
                      resourceSummary.natGateway === 'Active'
                        ? 'bg-green-200 text-green-800'
                        : resourceSummary.natGateway === 'Inactive'
                        ? 'bg-orange-200 text-orange-800'
                        : 'bg-gray-200 text-gray-800'
                    }`}>
                      {resourceSummary.natGateway}
                    </span>
                  </div>
                </div>
              ) : (
                <p className="text-gray-500">No resources deployed yet</p>
              )}

              {resourceSummary?.lastDeployment && (
                <div className="mt-4 pt-4 border-t">
                  <span className="font-semibold">Last Deployment:</span>{' '}
                  <span className="text-gray-700">{resourceSummary.lastDeployment}</span>
                </div>
              )}
            </div>

            <div className="bg-white shadow-md rounded p-6">
              <h3 className="text-xl font-semibold mb-4">Quick Actions</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                {quickActions.map((action, index) => (
                  <Link
                    key={index}
                    to={action.link}
                    className={`${action.color} hover:opacity-90 text-white rounded-lg p-6 transition-opacity flex flex-col items-center justify-center text-center`}
                  >
                    <span className="text-4xl mb-2">{action.icon}</span>
                    <span className="font-semibold">{action.title}</span>
                  </Link>
                ))}
              </div>
            </div>

            <div className="bg-blue-50 border border-blue-200 rounded p-6">
              <h3 className="font-semibold text-blue-900 mb-3">🚀 Getting Started</h3>
              <ol className="list-decimal list-inside text-blue-800 space-y-2">
                <li>Configure your Azure credentials in <Link to="/settings" className="underline font-semibold">Settings</Link></li>
                <li>Deploy infrastructure from the <Link to="/deployment" className="underline font-semibold">Deployment</Link> page</li>
                <li>Set up VPN certificates in <Link to="/vpn" className="underline font-semibold">VPN Management</Link></li>
                <li>Enable NAT Gateway for outbound connectivity if needed</li>
              </ol>
            </div>
          </>
        )}
      </div>
    </MainLayout>
  );
};

export default Dashboard;
