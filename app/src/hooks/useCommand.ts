
import { useState } from 'react';
import { invoke } from '../utils/invoke';
import toast from 'react-hot-toast';

type CommandExecutor = (command: string, description: string) => Promise<string | null>;

interface UseCommandResult {
  logs: string;
  isLoading: boolean;
  error: string | null;
  executeCommand: CommandExecutor;
}

export const useCommand = (): UseCommandResult => {
  const [logs, setLogs] = useState<string>('');
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const executeCommand: CommandExecutor = async (command: string, description: string) => {
    setIsLoading(true);
    setLogs('');
    setError(null);

    try {
      const result = await invoke('pwsh', ['-Command', command]);
      const output = result || 'Command executed successfully with no output.';
      setLogs(output);
      toast.success(`${description} completed successfully!`);
      return output;
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : String(err);
      setError(`Error during ${description}: ${errorMessage}`);
      setLogs(`Error: ${errorMessage}`);
      toast.error(`Error during ${description}: ${errorMessage}`);
      console.error(`Failed to execute ${description}:`, err);
      return null;
    } finally {
      setIsLoading(false);
    }
  };

  return { logs, isLoading, error, executeCommand };
};
