import React, { useState } from 'react';
import MainLayout from '../layout/MainLayout';
import { invoke } from '../../utils/invoke';

const Deployment: React.FC = () => {
  const [logs, setLogs] = useState<string>('');
  const [isDeploying, setIsDeploying] = useState<boolean>(false);

  const handleDeploy = async () => {
    setIsDeploying(true);
    setLogs('');

    try {
      const result = await invoke('pwsh', ['-Command', 'Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; Start-HomeLab']);
      setLogs(result);
    } catch (error) {
      if (error instanceof Error) {
        setLogs(error.message);
      } else {
        setLogs(String(error));
      }
    } finally {
      setIsDeploying(false);
    }
  };

  return (
    <MainLayout title="Deployment">
      <div className="deployment">
        <button onClick={handleDeploy} disabled={isDeploying}>
          {isDeploying ? 'Deploying...' : 'Start Deployment'}
        </button>
        <pre>{logs}</pre>
      </div>
    </MainLayout>
  );
};

export default Deployment;
