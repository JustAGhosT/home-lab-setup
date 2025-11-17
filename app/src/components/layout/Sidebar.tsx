import React from 'react';
import { NavLink } from 'react-router-dom';

const Sidebar: React.FC = () => {
  return (
    <div className="w-64 bg-gray-800 text-white">
      <div className="p-6">
        <h1 className="text-2xl font-semibold">HomeLab</h1>
      </div>
      <nav className="mt-6">
        <NavLink to="/" className="block py-2.5 px-4 rounded transition duration-200 hover:bg-gray-700">
          Dashboard
        </NavLink>
        <NavLink to="/deployment" className="block py-2.5 px-4 rounded transition duration-200 hover:bg-gray-700">
          Deployment
        </NavLink>
        <NavLink to="/vpn" className="block py-2.5 px-4 rounded transition duration-200 hover:bg-gray-700">
          VPN Management
        </NavLink>
        <NavLink to="/nat" className="block py-2.5 px-4 rounded transition duration-200 hover:bg-gray-700">
          NAT Gateway
        </NavLink>
        <NavLink to="/docs" className="block py-2.5 px-4 rounded transition duration-200 hover:bg-gray-700">
          Documentation
        </NavLink>
        <NavLink to="/settings" className="block py-2.5 px-4 rounded transition duration-200 hover:bg-gray-700">
          Settings
        </NavLink>
      </nav>
    </div>
  );
};

export default Sidebar;
