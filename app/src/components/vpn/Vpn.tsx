import React, { useState } from 'react';
import MainLayout from '../layout/MainLayout';
import { invoke } from '../../utils/invoke';

const Vpn: React.FC = () => {
  const [logs, setLogs] = useState<string>('');
  const [isGenerating, setIsGenerating] = useState<boolean>(false);

  const handleGenerate = async () => {
    setIsGenerating(true);
    setLogs('');

    try {
      const result = await invoke('pwsh', ['-Command', 'Import-Module /app/src/HomeLab/HomeLab/HomeLab.psd1; New-VpnCertificate']);
      setLogs(result);
    } catch (error) {
      if (error instanceof Error) {
        setLogs(error.message);
      } else {
        setLogs(String(error));
      }
    } finally {
      setIsGenerating(false);
    }
  };

  return (
    <MainLayout title="VPN Management">
      <div className="vpn">
        <button onClick={handleGenerate} disabled={isGenerating}>
          {isGenerating ? 'Generating...' : 'Generate VPN Certificate'}
        </button>
        <pre>{logs}</pre>
      </div>
    </MainLayout>
  );
};

export default Vpn;
