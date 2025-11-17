import React, { useState } from 'react';
import MainLayout from '../layout/MainLayout';
import { invoke } from '../../utils/invoke';

const Nat: React.FC = () => {
  const [logs, setLogs] = useState<string>('');
  const [isCreating, setIsCreating] = useState<boolean>(false);

  const handleCreate = async () => {
    setIsCreating(true);
    setLogs('');

    try {
      const result = await invoke('pwsh', ['-Command', 'Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; New-NatGateway']);
      setLogs(result);
    } catch (error) {
      if (error instanceof Error) {
        setLogs(error.message);
      } else {
        setLogs(String(error));
      }
    } finally {
      setIsCreating(false);
    }
  };

  return (
    <MainLayout title="NAT Gateway">
      <div className="nat">
        <button onClick={handleCreate} disabled={isCreating}>
          {isCreating ? 'Creating...' : 'Create NAT Gateway'}
        </button>
        <pre>{logs}</pre>
      </div>
    </MainLayout>
  );
};

export default Nat;
