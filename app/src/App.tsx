import React from 'react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import Dashboard from './components/dashboard/Dashboard';
import Deployment from './components/deployment/Deployment';
import Vpn from './components/vpn/Vpn';
import Nat from './components/nat/Nat';
import Docs from './components/docs/Docs';
import Settings from './components/settings/Settings';

const App: React.FC = () => {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/deployment" element={<Deployment />} />
        <Route path="/vpn" element={<Vpn />} />
        <Route path="/nat" element={<Nat />} />
        <Route path="/docs" element={<Docs />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Router>
  );
};

export default App;
