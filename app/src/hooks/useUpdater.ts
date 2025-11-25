import { useState, useEffect, useCallback } from 'react';
import { check, Update } from '@tauri-apps/plugin-updater';

export interface UpdateInfo {
  available: boolean;
  currentVersion: string;
  version?: string;
  date?: string;
  body?: string;
}

export interface UpdateProgress {
  downloaded: number;
  total: number;
  percentage: number;
}

export interface UseUpdaterResult {
  updateInfo: UpdateInfo | null;
  isChecking: boolean;
  isDownloading: boolean;
  isInstalling: boolean;
  progress: UpdateProgress | null;
  error: string | null;
  checkForUpdates: () => Promise<void>;
  downloadAndInstall: () => Promise<void>;
  dismissUpdate: () => void;
}

export const useUpdater = (): UseUpdaterResult => {
  const [updateInfo, setUpdateInfo] = useState<UpdateInfo | null>(null);
  const [isChecking, setIsChecking] = useState(false);
  const [isDownloading, setIsDownloading] = useState(false);
  const [isInstalling, setIsInstalling] = useState(false);
  const [progress, setProgress] = useState<UpdateProgress | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [updateInstance, setUpdateInstance] = useState<Update | null>(null);

  const checkForUpdates = useCallback(async () => {
    setIsChecking(true);
    setError(null);

    try {
      const update = await check();
      
      if (update) {
        setUpdateInstance(update);
        setUpdateInfo({
          available: true,
          currentVersion: update.currentVersion,
          version: update.version,
          date: update.date,
          body: update.body,
        });
      } else {
        setUpdateInfo({
          available: false,
          currentVersion: 'unknown',
        });
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : String(err);
      setError(`Failed to check for updates: ${errorMessage}`);
      console.error('Update check failed:', err);
    } finally {
      setIsChecking(false);
    }
  }, []);

  const downloadAndInstall = useCallback(async () => {
    if (!updateInstance) {
      setError('No update available to install');
      return;
    }

    setIsDownloading(true);
    setError(null);
    setProgress({ downloaded: 0, total: 0, percentage: 0 });

    try {
      // Download with progress tracking
      await updateInstance.downloadAndInstall((event) => {
        switch (event.event) {
          case 'Started':
            setProgress({
              downloaded: 0,
              total: event.data.contentLength || 0,
              percentage: 0,
            });
            break;
          case 'Progress':
            setProgress((prev) => {
              const downloaded = (prev?.downloaded || 0) + event.data.chunkLength;
              const total = prev?.total || 0;
              const percentage = total > 0 ? Math.round((downloaded / total) * 100) : 0;
              return { downloaded, total, percentage };
            });
            break;
          case 'Finished':
            setProgress((prev) => ({
              ...prev!,
              percentage: 100,
            }));
            setIsDownloading(false);
            setIsInstalling(true);
            break;
        }
      });

      // The app will restart after installation
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : String(err);
      setError(`Failed to download/install update: ${errorMessage}`);
      console.error('Update installation failed:', err);
      setIsDownloading(false);
      setIsInstalling(false);
    }
  }, [updateInstance]);

  const dismissUpdate = useCallback(() => {
    setUpdateInfo(null);
    setUpdateInstance(null);
  }, []);

  // Check for updates on mount
  useEffect(() => {
    // Delay initial check to allow app to fully load
    const timer = setTimeout(() => {
      checkForUpdates();
    }, 3000);

    return () => clearTimeout(timer);
  }, [checkForUpdates]);

  return {
    updateInfo,
    isChecking,
    isDownloading,
    isInstalling,
    progress,
    error,
    checkForUpdates,
    downloadAndInstall,
    dismissUpdate,
  };
};
