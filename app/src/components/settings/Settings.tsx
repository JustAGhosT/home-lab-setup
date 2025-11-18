import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import toast from 'react-hot-toast';
import MainLayout from '../layout/MainLayout';
import { fetchConfig, saveConfig, setConfigValue } from '../../store/configSlice';
import { RootState, AppDispatch } from '../../store/store';

// Helper to format labels and add tooltips
const settingMetadata: { [key: string]: { label: string; tooltip: string } } = {
  logFileLocation: {
    label: 'Log File Location',
    tooltip: 'The directory where log files should be stored.',
  },
  azureLocation: {
    label: 'Azure Location',
    tooltip: 'The default Azure region for resource deployment.',
  },
  projectName: {
    label: 'Project Name',
    tooltip: 'A name for your project, used for resource naming.',
  },
  environment: {
    label: 'Environment',
    tooltip: 'The deployment environment (e.g., dev, test, prod).',
  },
};

const Settings: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();
  const { config, loading, error } = useSelector((state: RootState) => state.config);

  useEffect(() => {
    dispatch(fetchConfig());
  }, [dispatch]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    dispatch(setConfigValue({ key: name, value }));
  };

  const handleSave = () => {
    dispatch(saveConfig(config));
    toast.success('Settings saved successfully!');
  };

  return (
    <MainLayout title="Settings">
      <div className="bg-white shadow-md rounded p-6">
        {loading && <p>Loading settings...</p>}
        {error && <p className="text-red-500">Error: {error}</p>}
        {config && (
          <form>
            {Object.entries(config).map(([key, value]) => (
              <div key={key} className="mb-4" title={settingMetadata[key]?.tooltip}>
                <label htmlFor={key} className="block text-gray-700 font-bold mb-2">
                  {settingMetadata[key]?.label || key}
                </label>
                <input
                  type="text"
                  id={key}
                  name={key}
                  value={String(value)}
                  onChange={handleChange}
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                />
              </div>
            ))}
            <button
              type="button"
              onClick={handleSave}
              className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
            >
              Save Settings
            </button>
          </form>
        )}
      </div>
    </MainLayout>
  );
};

export default Settings;
