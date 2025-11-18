import React from 'react';
import MainLayout from '../layout/MainLayout';

const Docs: React.FC = () => {
  return (
    <MainLayout title="Documentation">
      <div className="bg-white shadow-md rounded p-6">
        <h2 className="text-2xl font-bold mb-4">Documentation & Resources</h2>
        <div className="space-y-6">
          <section>
            <h3 className="text-xl font-semibold mb-3">🚀 Quick Start Guide</h3>
            <p className="text-gray-700">
              Follow these steps to get your HomeLab environment up and running:
            </p>
            <ol className="list-decimal list-inside mt-2 text-gray-700 space-y-1">
              <li>Configure your Azure credentials in the <strong>Settings</strong> page.</li>
              <li>Deploy your infrastructure from the <strong>Deployment</strong> page.</li>
              <li>Set up VPN certificates for secure access in <strong>VPN Management</strong>.</li>
              <li>Enable the <strong>NAT Gateway</strong> for outbound connectivity if required.</li>
            </ol>
          </section>
          
          <section>
            <h3 className="text-xl font-semibold mb-3">📚 External Resources</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <a 
                href="https://github.com/JustAGhosT/home-lab-setup/blob/main/README.md"
                target="_blank"
                rel="noopener noreferrer"
                className="block p-4 bg-blue-50 hover:bg-blue-100 rounded-lg transition-colors border border-blue-200"
              >
                <span className="text-2xl mr-3">📖</span>
                <span className="font-semibold text-blue-800">Main README</span>
              </a>
              <a 
                href="https://github.com/JustAGhosT/home-lab-setup/blob/main/QUICK-START.md"
                target="_blank"
                rel="noopener noreferrer"
                className="block p-4 bg-green-50 hover:bg-green-100 rounded-lg transition-colors border border-green-200"
              >
                <span className="text-2xl mr-3">⚡️</span>
                <span className="font-semibold text-green-800">Quick Start Guide</span>
              </a>
              <a 
                href="https://github.com/JustAGhosT/home-lab-setup/blob/main/docs/SETUP.md"
                target="_blank"
                rel="noopener noreferrer"
                className="block p-4 bg-purple-50 hover:bg-purple-100 rounded-lg transition-colors border border-purple-200"
              >
                <span className="text-2xl mr-3">🛠️</span>
                <span className="font-semibold text-purple-800">Detailed Setup Guide</span>
              </a>
            </div>
          </section>

          <section>
            <h3 className="text-lg font-medium mb-2">Components</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-2">
              <div className="border rounded p-3">
                <h4 className="font-medium">Deployment</h4>
                <p className="text-sm text-gray-600">Deploy Azure infrastructure including VNet, VPN Gateway, and NAT Gateway</p>
              </div>
              <div className="border rounded p-3">
                <h4 className="font-medium">VPN Management</h4>
                <p className="text-sm text-gray-600">Manage VPN certificates, gateway, and client connections</p>
              </div>
              <div className="border rounded p-3">
                <h4 className="font-medium">NAT Gateway</h4>
                <p className="text-sm text-gray-600">Control NAT Gateway for outbound internet connectivity</p>
              </div>
              <div className="border rounded p-3">
                <h4 className="font-medium">Settings</h4>
                <p className="text-sm text-gray-600">Configure environment, project name, location, and other settings</p>
              </div>
            </div>
          </section>
        </div>
      </div>
    </MainLayout>
  );
};

export default Docs;
