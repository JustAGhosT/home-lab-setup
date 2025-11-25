# HomeLab Desktop App Auto-Update

This document describes how the HomeLab desktop application handles automatic updates.

## Overview

The HomeLab desktop app uses [Tauri's built-in updater](https://tauri.app/v2/guides/features/updater/)
to check for and install updates automatically. Updates are hosted on GitHub Releases.

## How It Works

1. **Startup Check**: When the app launches, it waits 3 seconds then checks for updates
2. **Update Detection**: The app fetches `latest.json` from GitHub Releases
3. **User Prompt**: If a new version is available, a notification appears
4. **Download**: Users can choose to download and install immediately
5. **Installation**: The update is downloaded, verified, and installed
6. **Restart**: The app automatically restarts with the new version

## Update Hosting

Updates are hosted on GitHub Releases at:

```text
https://github.com/JustAGhosT/home-lab-setup/releases/latest/download/latest.json
```

The `latest.json` manifest contains:

- Version number
- Release notes
- Platform-specific download URLs
- Cryptographic signatures for verification

## Supported Platforms

| Platform | Architecture | Installer Format |
|----------|--------------|------------------|
| Windows | x64 | NSIS (.exe), MSI |
| macOS | x64 (Intel) | DMG, App Bundle |
| macOS | ARM64 (Apple Silicon) | DMG, App Bundle |
| Linux | x64 | AppImage, DEB |

## Setting Up Signing Keys

For security, all updates must be cryptographically signed. To set up signing:

### 1. Generate a Key Pair

```bash
# Using Tauri CLI
pnpm tauri signer generate -w ~/.tauri/homelab.key
```

This creates:
- Private key: `~/.tauri/homelab.key`
- Public key: Printed to console

### 2. Configure the Public Key

Add the public key to `app/src-tauri/tauri.conf.json`:

```json
{
  "plugins": {
    "updater": {
      "pubkey": "dW50cnVzdGVkIGNvbW1lbnQ6IG1pbmlzaWduIHB1YmxpYyBrZXk6...",
      "endpoints": [
        "https://github.com/JustAGhosT/home-lab-setup/releases/latest/download/latest.json"
      ]
    }
  }
}
```

### 3. Configure GitHub Secrets

Add these secrets to your GitHub repository:

- `TAURI_SIGNING_PRIVATE_KEY`: Contents of the private key file
- `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`: Password used when generating the key

## Partial Updates (Delta Updates)

Tauri 2.0 supports delta updates to minimize download size:

### How Delta Updates Work

1. **Full Update**: First installation downloads the complete app
2. **Subsequent Updates**: Only changed files are downloaded
3. **Rollback Support**: If delta fails, falls back to full update

### Configuration

Delta updates are automatically enabled when `createUpdaterArtifacts` is set to `true`
in the bundle configuration:

```json
{
  "bundle": {
    "createUpdaterArtifacts": true
  }
}
```

### Limitations

- Delta updates require the previous version to be installed
- Very large changes may result in full downloads
- Not available for major version upgrades

## Manual Update Check

Users can manually check for updates in the Settings page:

1. Open Settings (gear icon)
2. Click "Check for Updates"
3. Follow the prompts if an update is available

## Troubleshooting

### Update Check Fails

- Verify internet connectivity
- Check if GitHub is accessible
- Ensure firewall isn't blocking the app

### Signature Verification Fails

- The update file may be corrupted
- Try downloading again
- Check if the signing key has changed

### Installation Fails

- Ensure you have write permissions
- Check available disk space
- Try running as administrator (Windows)

## Development

### Testing Updates Locally

1. Build the app with a lower version number
2. Install and run it
3. Publish a new release with higher version
4. The app should detect and offer the update

### Debugging

Enable verbose logging in development:

```rust
tauri_plugin_log::Builder::default()
    .level(log::LevelFilter::Debug)
    .build()
```

## Security Considerations

- All updates are signed with Ed25519 signatures
- The public key is embedded in the app binary
- Signature verification happens before installation
- HTTPS is used for all downloads
- Updates cannot be downgraded to older versions
