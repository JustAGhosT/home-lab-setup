import React from 'react';
import { useUpdater } from '../../hooks/useUpdater';
import { AppConfig } from '../../constants/app';

const UpdateNotification: React.FC = () => {
  const {
    updateInfo,
    isChecking,
    isDownloading,
    isInstalling,
    progress,
    error,
    checkForUpdates,
    downloadAndInstall,
    dismissUpdate,
  } = useUpdater();

  // Don't render if no update available or still checking
  if (isChecking || !updateInfo?.available) {
    return null;
  }

  return (
    <div className="fixed bottom-4 right-4 z-50 max-w-md">
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-xl border border-gray-200 dark:border-gray-700 overflow-hidden">
        {/* Header */}
        <div className="bg-gradient-to-r from-blue-500 to-blue-600 px-4 py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <svg
                className="w-5 h-5 text-white"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"
                />
              </svg>
              <h3 className="text-white font-semibold">Update Available</h3>
            </div>
            {!isDownloading && !isInstalling && (
              <button
                onClick={dismissUpdate}
                className="text-white/80 hover:text-white transition-colors"
                aria-label="Dismiss"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            )}
          </div>
        </div>

        {/* Content */}
        <div className="p-4">
          <div className="mb-3">
            <p className="text-sm text-gray-600 dark:text-gray-300">
              A new version of {AppConfig.name} is available!
            </p>
            <div className="mt-2 flex items-center space-x-2 text-sm">
              <span className="text-gray-500 dark:text-gray-400">
                {updateInfo.currentVersion}
              </span>
              <svg className="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
              </svg>
              <span className="text-blue-600 dark:text-blue-400 font-medium">
                {updateInfo.version}
              </span>
            </div>
          </div>

          {/* Release notes */}
          {updateInfo.body && (
            <div className="mb-3 p-2 bg-gray-50 dark:bg-gray-700/50 rounded text-xs text-gray-600 dark:text-gray-300 max-h-24 overflow-y-auto">
              <p className="font-medium mb-1">What's new:</p>
              <p className="whitespace-pre-wrap">{updateInfo.body}</p>
            </div>
          )}

          {/* Progress bar */}
          {(isDownloading || isInstalling) && progress && (
            <div className="mb-3">
              <div className="flex justify-between text-xs text-gray-500 dark:text-gray-400 mb-1">
                <span>{isInstalling ? 'Installing...' : 'Downloading...'}</span>
                <span>{progress.percentage}%</span>
              </div>
              <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                <div
                  className="bg-blue-500 h-2 rounded-full transition-all duration-300"
                  style={{ width: `${progress.percentage}%` }}
                />
              </div>
              {!isInstalling && progress.total > 0 && (
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                  {formatBytes(progress.downloaded)} / {formatBytes(progress.total)}
                </p>
              )}
            </div>
          )}

          {/* Error message */}
          {error && (
            <div className="mb-3 p-2 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded text-xs text-red-600 dark:text-red-400">
              {error}
            </div>
          )}

          {/* Actions */}
          <div className="flex space-x-2">
            {!isDownloading && !isInstalling && (
              <>
                <button
                  onClick={downloadAndInstall}
                  className="flex-1 px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white text-sm font-medium rounded transition-colors"
                >
                  Update Now
                </button>
                <button
                  onClick={dismissUpdate}
                  className="px-4 py-2 bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-300 text-sm font-medium rounded transition-colors"
                >
                  Later
                </button>
              </>
            )}
            {isInstalling && (
              <p className="text-sm text-gray-600 dark:text-gray-300">
                Installing update... The app will restart shortly.
              </p>
            )}
          </div>

          {/* Manual check button */}
          {error && (
            <button
              onClick={checkForUpdates}
              className="mt-2 w-full px-4 py-2 bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-300 text-sm font-medium rounded transition-colors"
            >
              Retry
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

// Helper function to format bytes
function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(1))} ${sizes[i]}`;
}

export default UpdateNotification;
