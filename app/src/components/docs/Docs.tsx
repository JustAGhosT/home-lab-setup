import React from 'react';
import MainLayout from '../layout/MainLayout';

const Docs: React.FC = () => {
  return (
    <MainLayout title="Documentation">
      <div className="bg-white shadow-md rounded p-6">
        <h2 className="text-xl font-semibold mb-4">HomeLab Documentation</h2>
        <div className="space-y-4">
          <section>
            <h3 className="text-lg font-medium mb-2">Quick Start</h3>
            <p className="text-gray-700">
              Get started with the HomeLab setup by following these steps:
            </p>
            <ul className="list-disc list-inside mt-2 text-gray-700">
              <li>Configure your Azure credentials in Settings</li>
              <li>Deploy the infrastructure from the Deployment page</li>
              <li>Set up VPN certificates for secure access</li>
              <li>Configure NAT Gateway for outbound connectivity</li>
            </ul>
          </section>
          
          <section>
            <h3 className="text-lg font-medium mb-2">Resources</h3>
            <div className="space-y-2">
              <a 
                href="https://github.com/JustAGhosT/home-lab-setup/blob/main/README.md"
                target="_blank"
                rel="noopener noreferrer"
                className="block text-blue-600 hover:text-blue-800 underline"
              >
                Main README
              </a>
              <a 
                href="https://github.com/JustAGhosT/home-lab-setup/blob/main/QUICK-START.md"
                target="_blank"
                rel="noopener noreferrer"
                className="block text-blue-600 hover:text-blue-800 underline"
              >
                Quick Start Guide
              </a>
              <a 
                href="https://github.com/JustAGhosT/home-lab-setup/blob/main/docs/SETUP.md"
                target="_blank"
                rel="noopener noreferrer"
                className="block text-blue-600 hover:text-blue-800 underline"
              >
                Setup Guide
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
