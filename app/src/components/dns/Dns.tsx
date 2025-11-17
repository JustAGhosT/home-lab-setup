import React, { useState } from 'react';
import MainLayout from '../layout/MainLayout';
import { invoke } from '../../utils/invoke';

interface DnsZone {
  name: string;
  resourceGroup: string;
  numberOfRecordSets: number;
  nameServers: string[];
}

interface DnsRecord {
  name: string;
  type: string;
  value: string;
  ttl: number;
}

const Dns: React.FC = () => {
  const [zones, setZones] = useState<DnsZone[]>([]);
  const [records, setRecords] = useState<DnsRecord[]>([]);
  const [logs, setLogs] = useState<string>('');
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [activeOperation, setActiveOperation] = useState<string>('');
  const [selectedZone, setSelectedZone] = useState<string>('');

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

  const handleCreateZone = async () => {
    await executeCommand(
      'Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; New-DnsZone',
      'Creating DNS Zone'
    );
  };

  const handleAddRecord = async () => {
    await executeCommand(
      'Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; Add-DnsRecord',
      'Adding DNS Record'
    );
  };

  const handleListZones = async () => {
    setIsLoading(true);
    setActiveOperation('Listing DNS Zones');
    setLogs('');

    try {
      const result = await invoke('pwsh', [
        '-Command',
        'Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; Get-DnsZones | ConvertTo-Json'
      ]);
      const zoneList = JSON.parse(result);
      setZones(Array.isArray(zoneList) ? zoneList : [zoneList]);
      setLogs('DNS zones loaded successfully');
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

  const handleListRecords = async (zoneName?: string) => {
    const zone = zoneName || selectedZone;
    if (!zone) {
      setLogs('Error: Please select a DNS zone first');
      return;
    }

    setIsLoading(true);
    setActiveOperation('Listing DNS Records');
    setLogs('');

    try {
      const result = await invoke('pwsh', [
        '-Command',
        `Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; Get-DnsRecords -ZoneName '${zone}' | ConvertTo-Json`
      ]);
      const recordList = JSON.parse(result);
      setRecords(Array.isArray(recordList) ? recordList : [recordList]);
      setLogs('DNS records loaded successfully');
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

  const handleDeleteZone = async (zoneName: string) => {
    if (window.confirm(`Are you sure you want to delete DNS zone "${zoneName}"? This action cannot be undone.`)) {
      await executeCommand(
        `Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; Remove-DnsZone -ZoneName '${zoneName}'`,
        `Deleting DNS Zone: ${zoneName}`
      );
    }
  };

  return (
    <MainLayout title="DNS Management">
      <div className="dns space-y-6">
        <div className="bg-white shadow-md rounded p-6">
          <h2 className="text-xl font-semibold mb-4">DNS Zone Management</h2>
          <p className="text-gray-600 mb-6">
            Manage Azure DNS zones and records for your custom domains
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
            <button
              onClick={handleCreateZone}
              disabled={isLoading}
              className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              Create Zone
            </button>

            <button
              onClick={handleAddRecord}
              disabled={isLoading}
              className="bg-green-500 hover:bg-green-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              Add Record
            </button>

            <button
              onClick={handleListZones}
              disabled={isLoading}
              className="bg-purple-500 hover:bg-purple-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              List Zones
            </button>

            <button
              onClick={() => handleListRecords()}
              disabled={isLoading || !selectedZone}
              className="bg-orange-500 hover:bg-orange-700 text-white font-bold py-3 px-4 rounded disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              List Records
            </button>
          </div>

          {isLoading && (
            <div className="mb-4 p-4 bg-blue-100 border border-blue-300 rounded">
              <p className="text-blue-800">
                <span className="font-semibold">In Progress:</span> {activeOperation}...
              </p>
            </div>
          )}

          {zones.length > 0 && (
            <div className="mb-6">
              <h3 className="text-lg font-medium mb-3">DNS Zones</h3>
              <div className="overflow-x-auto">
                <table className="min-w-full bg-white border border-gray-300">
                  <thead className="bg-gray-100">
                    <tr>
                      <th className="px-4 py-2 text-left border-b">Zone Name</th>
                      <th className="px-4 py-2 text-left border-b">Resource Group</th>
                      <th className="px-4 py-2 text-left border-b">Record Sets</th>
                      <th className="px-4 py-2 text-left border-b">Name Servers</th>
                      <th className="px-4 py-2 text-left border-b">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {zones.map((zone, index) => (
                      <tr key={index} className="hover:bg-gray-50">
                        <td className="px-4 py-2 border-b font-semibold">{zone.name}</td>
                        <td className="px-4 py-2 border-b">{zone.resourceGroup}</td>
                        <td className="px-4 py-2 border-b">{zone.numberOfRecordSets}</td>
                        <td className="px-4 py-2 border-b">
                          <details className="cursor-pointer">
                            <summary className="text-blue-600 hover:text-blue-800">
                              View ({zone.nameServers?.length || 0})
                            </summary>
                            <ul className="mt-2 text-xs font-mono">
                              {zone.nameServers?.map((ns, i) => (
                                <li key={i}>{ns}</li>
                              ))}
                            </ul>
                          </details>
                        </td>
                        <td className="px-4 py-2 border-b space-x-2">
                          <button
                            onClick={() => {
                              setSelectedZone(zone.name);
                              handleListRecords(zone.name);
                            }}
                            className="text-blue-600 hover:text-blue-800 font-semibold"
                          >
                            View Records
                          </button>
                          <button
                            onClick={() => handleDeleteZone(zone.name)}
                            className="text-red-600 hover:text-red-800 font-semibold"
                          >
                            Delete
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {records.length > 0 && selectedZone && (
            <div className="mb-6">
              <h3 className="text-lg font-medium mb-3">DNS Records for: {selectedZone}</h3>
              <div className="overflow-x-auto">
                <table className="min-w-full bg-white border border-gray-300">
                  <thead className="bg-gray-100">
                    <tr>
                      <th className="px-4 py-2 text-left border-b">Name</th>
                      <th className="px-4 py-2 text-left border-b">Type</th>
                      <th className="px-4 py-2 text-left border-b">Value</th>
                      <th className="px-4 py-2 text-left border-b">TTL</th>
                    </tr>
                  </thead>
                  <tbody>
                    {records.map((record, index) => (
                      <tr key={index} className="hover:bg-gray-50">
                        <td className="px-4 py-2 border-b font-semibold">{record.name}</td>
                        <td className="px-4 py-2 border-b">
                          <span className="px-2 py-1 bg-blue-100 text-blue-800 rounded text-xs font-semibold">
                            {record.type}
                          </span>
                        </td>
                        <td className="px-4 py-2 border-b font-mono text-sm">{record.value}</td>
                        <td className="px-4 py-2 border-b">{record.ttl}s</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
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
          <h3 className="font-semibold text-blue-900 mb-2">💡 DNS Management Tips</h3>
          <ul className="list-disc list-inside text-blue-800 space-y-1">
            <li>DNS zones cost approximately $0.50/month per zone plus query charges</li>
            <li>After creating a zone, update your domain registrar with the Azure name servers</li>
            <li>DNS changes can take up to 48 hours to propagate globally</li>
            <li>Use appropriate TTL values (300-3600 seconds recommended)</li>
          </ul>
        </div>

        <div className="bg-yellow-50 border border-yellow-200 rounded p-4">
          <h3 className="font-semibold text-yellow-900 mb-2">⚠️ Important Notes</h3>
          <ul className="list-disc list-inside text-yellow-800 space-y-1">
            <li>Deleting a DNS zone will remove all associated records</li>
            <li>Verify DNS propagation using tools like nslookup or dig</li>
            <li>Common record types: A (IPv4), AAAA (IPv6), CNAME (alias), MX (mail), TXT (text)</li>
            <li>Always keep SOA and NS records for proper zone delegation</li>
          </ul>
        </div>
      </div>
    </MainLayout>
  );
};

export default Dns;
