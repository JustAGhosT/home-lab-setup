import React, { useState, useEffect } from 'react';
import { invoke } from '../../utils/invoke';
import { SecurityCommands } from '../../constants/commands';
import toast from 'react-hot-toast';

interface Certificate {
  name: string;
  thumbprint: string;
  expirationDate: string;
  isRoot: boolean;
}

const VpnCertificates: React.FC = () => {
  const [certificates, setCertificates] = useState<Certificate[]>([]);
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
    handleListCertificates();
  }, []);

  const handleCreateRootCertificate = async () => {
    await executeCommand(SecurityCommands.createRootCert(), 'Creating Root Certificate');
    handleListCertificates();
  };

  const handleCreateClientCertificate = async () => {
    await executeCommand(SecurityCommands.createClientCert(), 'Creating Client Certificate');
    handleListCertificates();
  };

  const handleAddClientToRoot = async () => {
    await executeCommand(SecurityCommands.addClientToRoot(), 'Adding Client Certificate to Root');
    handleListCertificates();
  };

  const handleUploadToGateway = async () => {
    await executeCommand(SecurityCommands.uploadToGateway(), 'Uploading Certificate to Gateway');
  };

  const handleListCertificates = async () => {
    setIsLoading(true);
    setActiveOperation('Listing Certificates');
    setLogs('');
    setError(null);

    try {
      const result = await invoke('pwsh', ['-Command', SecurityCommands.listCertificates()]);
      const certs = JSON.parse(result);
      setCertificates(Array.isArray(certs) ? certs : [certs]);
      setLogs('Certificates loaded successfully');
      toast.success('Certificates loaded!');
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : String(err);
      setError(`Error listing certificates: ${errorMessage}`);
      setLogs(`Error: ${errorMessage}`);
      toast.error(`Error listing certificates: ${errorMessage}`);
    } finally {
      setIsLoading(false);
      setActiveOperation('');
    }
  };

  return (
    <div className="space-y-6">
      <div className="bg-white shadow-md rounded p-6">
        <h2 className="text-xl font-semibold mb-4">VPN Certificate Management</h2>
        <p className="text-gray-600 mb-6">
          Manage VPN certificates for secure Point-to-Site connections
        </p>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
          <button
            onClick={handleCreateRootCertificate}
            disabled={isLoading}
            className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            Create Root Certificate
          </button>
          
          <button
            onClick={handleCreateClientCertificate}
            disabled={isLoading}
            className="bg-green-500 hover:bg-green-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            Create Client Certificate
          </button>
          
          <button
            onClick={handleAddClientToRoot}
            disabled={isLoading}
            className="bg-purple-500 hover:bg-purple-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            Add Client to Root
          </button>
          
          <button
            onClick={handleUploadToGateway}
            disabled={isLoading}
            className="bg-orange-500 hover:bg-orange-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            Upload to Gateway
          </button>
          
          <button
            onClick={handleListCertificates}
            disabled={isLoading}
            className="bg-indigo-500 hover:bg-indigo-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            Refresh Certificates
          </button>
        </div>

        {error && !isLoading && (
            <div className="mb-4 p-4 bg-red-50 border border-red-300 text-red-800 rounded-lg">
                <h3 className="font-semibold mb-2">⚠️ Certificate Error</h3>
                <p className="text-sm">{error}</p>
            </div>
        )}

        {isLoading && (
            <div className="flex items-center justify-center p-4 bg-blue-50 border border-blue-200 rounded-lg">
                <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-blue-500"></div>
                <p className="ml-4 text-blue-800 font-semibold">In Progress: {activeOperation}...</p>
            </div>
        )}

        {logs && !isLoading && (
          <div className="mb-4">
            <h3 className="text-lg font-medium mb-2">Output:</h3>
            <pre className="bg-gray-900 text-green-400 p-4 rounded overflow-x-auto max-h-96">
              {logs}
            </pre>
          </div>
        )}

        {certificates.length > 0 && (
          <div>
            <h3 className="text-lg font-medium mb-2">Certificates:</h3>
            <div className="overflow-x-auto">
              <table className="min-w-full bg-white border border-gray-300">
                <thead className="bg-gray-100">
                  <tr>
                    <th className="px-4 py-2 text-left border-b">Name</th>
                    <th className="px-4 py-2 text-left border-b">Type</th>
                    <th className="px-4 py-2 text-left border-b">Thumbprint</th>
                    <th className="px-4 py-2 text-left border-b">Expiration</th>
                  </tr>
                </thead>
                <tbody>
                  {certificates.map((cert, index) => (
                    <tr key={index} className="hover:bg-gray-50">
                      <td className="px-4 py-2 border-b">{cert.name}</td>
                      <td className="px-4 py-2 border-b">
                        <span className={`px-2 py-1 rounded text-xs font-semibold ${
                          cert.isRoot ? 'bg-blue-200 text-blue-800' : 'bg-green-200 text-green-800'
                        }`}>
                          {cert.isRoot ? 'Root' : 'Client'}
                        </span>
                      </td>
                      <td className="px-4 py-2 border-b font-mono text-sm">{cert.thumbprint}</td>
                      <td className="px-4 py-2 border-b">{cert.expirationDate}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default VpnCertificates;
