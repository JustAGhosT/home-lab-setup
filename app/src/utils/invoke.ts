import { Command } from '@tauri-apps/plugin-shell';

export async function invoke(command: string, args: string[]): Promise<string> {
  const cmd = Command.create(command, args);
  const { stdout, stderr } = await cmd.execute();

  if (stderr) {
    throw new Error(stderr);
  }

  return stdout;
}
