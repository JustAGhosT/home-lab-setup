# Software KVM Alternatives: Synergy and Barrier

## Overview

This document explores software alternatives to hardware KVM switches, focusing on Synergy and Barrier. These solutions allow you to share a single keyboard and mouse across multiple computers over a network connection, creating a seamless multi-device workspace.

## Software KVM Benefits

- **No Additional Hardware**: Uses your existing network infrastructure
- **Cross-Platform Support**: Works across Windows, macOS, and Linux
- **Clipboard Sharing**: Copy and paste text and files between computers
- **Flexible Configuration**: Customize screen arrangements regardless of physical placement
- **Cost-Effective**: Generally less expensive than hardware KVM solutions
- **Drag-and-Drop**: Some solutions support dragging files between computers

## Available Software Solutions

### Barrier (Open Source)

Barrier is a free, open-source software fork of Synergy 1.9 that continues development with community support.

- **Cost**: Free (Open Source)
- **Platforms**: Windows, macOS, Linux
- **Features**:
  - Keyboard and mouse sharing
  - Clipboard sharing (text only)
  - Screen transition configuration
  - SSL encryption
  - Auto-start capability
- **Limitations**:
  - No drag-and-drop file transfer
  - Occasional connectivity issues
  - Limited support resources
- **Download**: [GitHub Repository](https://github.com/debauchee/barrier/releases)

#### Barrier Setup Instructions

1. **Installation**:
   - Download the appropriate installer for each operating system
   - Install on all computers you want to include in your setup

2. **Server Configuration** (Primary computer with physical keyboard/mouse):
   - Launch Barrier
   - Select "Server (share this computer's mouse and keyboard)"
   - Click "Configure Server"
   - Add screens by clicking the "+" button (each screen represents a computer)
   - Arrange screens to match your physical monitor layout
   - Save the configuration

3. **Client Configuration** (Secondary computers):
   - Launch Barrier
   - Select "Client (use another computer's mouse and keyboard)"
   - Enter the server's IP address
   - Set the screen name to match what you configured on the server

4. **Starting the Connection**:
   - Start the server on your primary computer
   - Start the client on all secondary computers
   - The status should change to "Connected"

5. **Security Settings**:
   - Enable SSL encryption for secure communication
   - Set a password if operating in an untrusted network

### Synergy (Commercial)

Synergy is the commercial version with additional features and official support.

- **Cost**:
  - Synergy 3: $29 (one-time license, up to 3 computers)
  - Synergy 3 Ultimate: $49 (one-time license, up to 15 computers)
  - Business: subscription-based (contact Symless for pricing)
- **Platforms**: Windows, macOS, Linux
- **Features**:
  - All Barrier features
  - Drag-and-drop file transfer (Pro/Business)
  - SSL encryption
  - Auto-config via cloud account
  - Technical support
  - Remote access (Business)
- **Website**: [Synergy](https://symless.com/synergy)

#### Synergy Setup Instructions

1. **Purchase and Download**:
   - Purchase the appropriate license
   - Download the installer for each operating system
   - Install on all computers in your setup

2. **Account Setup** (Pro/Business):
   - Create a Synergy account
   - Log in on all computers

3. **Server Configuration**:
   - Launch Synergy on your primary computer
   - Select "Server" mode
   - Add and arrange screens in the configuration
   - Save the configuration

4. **Client Configuration**:
   - Launch Synergy on secondary computers
   - Select "Client" mode
   - Enter the server's IP address or use auto-discovery

5. **Advanced Features**:
   - Configure hotkeys for specific actions
   - Set up drag-and-drop file transfer (Pro/Business)
   - Configure SSL encryption

### Mouse Without Borders (Microsoft)

A free alternative developed by Microsoft Garage specifically for Windows systems.

- **Cost**: Free
- **Platforms**: Windows only
- **Features**:
  - Control up to four computers
  - Keyboard and mouse sharing
  - Clipboard sharing
  - File transfer
  - Screen capture sharing
- **Limitations**:
  - Windows only
  - Limited configuration options
  - No encryption options
- **Download**: [Microsoft Garage](https://www.microsoft.com/en-us/download/details.aspx?id=35460)

#### Mouse Without Borders Setup

1. **Download and Install**:
   - Download and install on all Windows computers

2. **Initial Setup**:
   - On first run, choose "New Setup"
   - Note the security code and computer name
   - On other computers, choose "I already have a setup" and enter the code

3. **Configuration**:
   - Arrange computers in the desired layout
   - Configure keyboard shortcuts as needed

### ShareMouse (Commercial)

A commercial solution with both free and paid versions.

- **Cost**:
  - Free: Limited to 2 computers with basic features
  - Standard: $49.95 (one-time purchase)
  - Pro: $99.95 (one-time purchase)
- **Platforms**: Windows, macOS
- **Features**:
  - Auto-configuration
  - File drag-and-drop
  - Clipboard sharing
  - Monitor dimming for inactive computers
  - Remote desktop switching
- **Website**: [ShareMouse](https://www.sharemouse.com/)

## Performance Considerations

### Network Requirements

- **Wired Connection Recommended**: For lowest latency and most reliable operation
- **Low Latency Network**: Ideally <10ms between devices
- **Stable Connection**: Network interruptions will disrupt keyboard/mouse sharing
- **Firewall Configuration**: May need to allow specific ports (typically 24800 for Synergy/Barrier)

### System Resource Usage

- **CPU Usage**: Minimal (<1-2% on modern systems)
- **Memory Usage**: 50-100MB typically
- **Network Bandwidth**: Minimal for keyboard/mouse, higher when transferring files or clipboard content

## Troubleshooting Common Issues

### Connection Problems

1. **Firewall Blocking**:
   - Ensure your firewall allows the application on all computers
   - Check that the required ports are open (typically 24800 for Synergy/Barrier)

2. **IP Address Changes**:
   - Use computer names instead of IP addresses when possible
   - Consider setting static IP addresses for your computers

3. **SSL Certificate Issues**:
   - Generate new certificates if you encounter SSL handshake failures
   - Ensure time synchronization between computers

### Input Lag

1. **Network Congestion**:
   - Use a wired connection instead of Wi-Fi
   - Ensure no high-bandwidth activities are occurring during use

2. **System Load**:
   - Check for resource-intensive applications running on either system
   - Close unnecessary applications

### Clipboard Sharing Issues

1. **Large Content**:
   - Some solutions limit clipboard size
   - Break large transfers into smaller chunks

2. **Format Compatibility**:
   - Some formats may not transfer correctly between different operating systems
   - Use plain text when possible for maximum compatibility

## Comparison with Hardware KVM

| Feature | Software KVM (Synergy/Barrier) | Hardware KVM |
|---------|--------------------------------|-------------|
| Cost | $0-99 | $30-500+ |
| Setup Complexity | Moderate | Low |
| Latency | Low-Moderate (network dependent) | None |
| Reliability | Depends on network | Very high |
| OS Independence | No (requires software on each OS) | Yes |
| Clipboard Sharing | Yes | Limited/No |
| File Transfer | Some solutions | No |
| Security Concerns | Network exposure | None |
| Multiple Monitor Support | Yes | Limited by hardware |
| Remote Access Potential | Yes | No |

## Recommendation for Your Setup

Based on your home lab configuration with multiple computers (P1 Mini-PC, L1 and L2 laptops) and mobile devices:

1. **Try Barrier First**: As a free solution, it's worth testing to see if it meets your needs
2. **Consider Synergy Pro**: If you need reliable file transfer between systems
3. **Hybrid Approach**: Use software KVM for day-to-day use, keep a basic hardware KVM as backup

## Setup Instructions for Your Specific Configuration

### Initial Setup with Barrier

1. **Install Barrier on All Computers**:
   - P1 (Mini-PC): Set as server
   - L1 (Laptop 1): Set as client
   - L2 (Laptop 2): Set as client

2. **Configure Screen Layout**:
   ```
   +-------+-------+
   |       |       |
   |  L1   |  P1   |
   |       |       |
   +-------+-------+
           |       |
           |  L2   |
           |       |
           +-------+
   ```

3. **Network Configuration**:
   - Ensure all devices are on the same subnet
   - Consider setting static IP addresses
   - Configure firewall exceptions on all systems

4. **Hotkey Configuration**:
   - Set up hotkeys to quickly switch focus between computers
   - Configure screen edge transitions to match your physical monitor layout

This software KVM solution provides a cost-effective way to control multiple computers in your home lab while enabling additional features like clipboard sharing that aren't available with basic hardware KVMs.
