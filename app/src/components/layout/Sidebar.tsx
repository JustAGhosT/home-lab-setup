import React from 'react';
import { NavLink } from 'react-router-dom';

const Sidebar: React.FC = () => {
  const navLinkClasses = ({ isActive }: { isActive: boolean }) =>
    `block py-2.5 px-4 rounded transition duration-200 ${
      isActive ? 'bg-gray-700' : 'hover:bg-gray-700'
    }`;

  return (
    <div className="w-64 bg-gray-800 text-white">
      <div className="p-6">
        <h1 className="text-2xl font-semibold">HomeLab</h1>
      </div>
      <nav className="mt-6">
        <NavLink to="/" className={navLinkClasses}>
          Dashboard
        </NavLink>
        <NavLink to="/deployment" className={navLinkClasses}>
          Deployment
        </NavLink>
        <NavLink to="/vpn" className={navLinkClasses}>
          VPN Management
        </NavLink>
        <NavLink to="/nat" className={navLinkClasses}>
          NAT Gateway
        </NavLink>
        <NavLink to="/dns" className={navLinkClasses}>
          DNS Management
        </NavLink>
        <NavLink to="/docs" className={navLinkClasses}>
          Documentation
        </NavLink>
        <NavLink to="/settings" className={navLinkClasses}>
          Settings
        </NavLink>
      </nav>
    </div>
  );
};

export default Sidebar;
