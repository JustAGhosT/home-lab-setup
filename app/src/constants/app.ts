/**
 * Application configuration constants
 * Centralizes app-wide configuration values
 */

/**
 * Application metadata
 */
export const AppConfig = {
  name: 'HomeLab',
  identifier: 'com.homelab.dev',
  displayName: 'HomeLab Desktop',
} as const;

/**
 * Update configuration
 */
export const UpdateConfig = {
  checkDelayMs: 3000, // Delay before checking for updates on startup
  updateEndpoint: 'https://github.com/JustAGhosT/home-lab-setup/releases/latest/download/latest.json',
} as const;
