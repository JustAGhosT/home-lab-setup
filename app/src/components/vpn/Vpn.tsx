import React, { useState } from 'react';
import MainLayout from '../layout/MainLayout';
import VpnCertificates from './VpnCertificates';
import VpnGateway from './VpnGateway';
import VpnClient from './VpnClient';

type VpnTab = 'certificates' | 'gateway' | 'client';

const Vpn: React.FC = () => {
  const [activeTab, setActiveTab] = useState<VpnTab>('certificates');

  const tabs = [
    { id: 'certificates' as VpnTab, label: 'Certificates', icon: '🔐' },
    { id: 'gateway' as VpnTab, label: 'Gateway', icon: '🌐' },
    { id: 'client' as VpnTab, label: 'Client', icon: '💻' },
  ];

  return (
    <MainLayout title="VPN Management">
      <div className="vpn">
        <div className="mb-6 border-b border-gray-200">
          <nav className="flex space-x-4">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`py-3 px-4 font-medium text-sm border-b-2 transition-colors ${
                  activeTab === tab.id
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <span className="mr-2">{tab.icon}</span>
                {tab.label}
              </button>
            ))}
          </nav>
        </div>

        <div className="tab-content">
          {activeTab === 'certificates' && <VpnCertificates />}
          {activeTab === 'gateway' && <VpnGateway />}
          {activeTab === 'client' && <VpnClient />}
        </div>
      </div>
    </MainLayout>
  );
};

export default Vpn;
