import { Command } from '@tauri-apps/api/shell';

export async function invoke(command: string, args: string[]): Promise<string> {
  const cmd = new Command(command, args);
  const { stdout, stderr } = await cmd.execute();

  if (stderr) {
    throw new Error(stderr);
  }

  return stdout;
}
