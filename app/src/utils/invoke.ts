import { Command } from '@tauri-apps/plugin-shell';

/**
 * Invokes a shell command with proper error handling and validation
 * @param command - The command to execute
 * @param args - Array of command arguments
 * @returns Promise resolving to command output
 * @throws Error if command fails or validation fails
 */
export async function invoke(command: string, args: string[]): Promise<string> {
  // Bug fix: Validate inputs before execution
  if (!command || typeof command !== 'string') {
    throw new Error('Invalid command: command must be a non-empty string');
  }
  
  if (!Array.isArray(args)) {
    throw new Error('Invalid arguments: args must be an array');
  }

  try {
    const cmd = Command.create(command, args);
    const { stdout, stderr, code } = await cmd.execute();

    // Bug fix: Check exit code in addition to stderr
    if (code !== 0) {
      throw new Error(`Command failed with exit code ${code}: ${stderr || 'Unknown error'}`);
    }

    // Bug fix: Only throw on stderr if exit code indicates failure
    // Some commands write warnings to stderr but succeed
    if (stderr && stderr.trim() !== '') {
      console.warn(`Command warning: ${stderr}`);
    }

    return stdout || '';
  } catch (error) {
    // Bug fix: Provide more context in error messages
    if (error instanceof Error) {
      throw new Error(`Failed to execute command "${command}": ${error.message}`);
    }
    throw new Error(`Failed to execute command "${command}": Unknown error`);
  }
}
