import React, { useState } from 'react';
import MainLayout from '../layout/MainLayout';
import VpnCertificates from './VpnCertificates';
import VpnGateway from './VpnGateway';
import VpnClient from './VpnClient';

const Vpn: React.FC = () => {
  const [activeTab, setActiveTab] = useState('certificates');

  const renderContent = () => {
    switch (activeTab) {
      case 'certificates':
        return <VpnCertificates />;
      case 'gateway':
        return <VpnGateway />;
      case 'client':
        return <VpnClient />;
      default:
        return null;
    }
  };

  return (
    <MainLayout title="VPN Management">
      <div className="vpn">
        <div className="flex border-b">
          <button
            className={`py-2 px-4 ${activeTab === 'certificates' ? 'border-b-2 border-blue-500' : ''}`}
            onClick={() => setActiveTab('certificates')}
          >
            Certificates
          </button>
          <button
            className={`py-2 px-4 ${activeTab === 'gateway' ? 'border-b-2 border-blue-500' : ''}`}
            onClick={() => setActiveTab('gateway')}
          >
            Gateway
          </button>
          <button
            className={`py-2 px-4 ${activeTab === 'client' ? 'border-b-2 border-blue-500' : ''}`}
            onClick={() => setActiveTab('client')}
          >
            Client
          </button>
        </div>
        <div className="p-6">{renderContent()}</div>
      </div>
    </MainLayout>
  );
};

export default Vpn;
