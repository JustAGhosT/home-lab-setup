# Keyboard Shortcuts Guide

This document provides a comprehensive guide to keyboard shortcuts available in the HomeLab Dashboard application.

## Navigation Shortcuts

These shortcuts help you quickly navigate between different sections of the application:

| Shortcut | Description |
| -------- | ----------- |
| `Ctrl + D` | Go to Dashboard |
| `Ctrl + P` | Go to Deployment page |
| `Ctrl + V` | Go to VPN Management |
| `Ctrl + N` | Go to NAT Gateway |
| `Ctrl + S` | Go to Settings |
| `Ctrl + H` | Go to Help/Documentation |

## Operation Shortcuts

Perform common operations quickly:

| Shortcut | Description |
| -------- | ----------- |
| `Ctrl + R` | Refresh current page |
| `Ctrl + Shift + E` | Export logs |
| `Ctrl + Shift + T` | Toggle dark/light mode |

## General Shortcuts

| Shortcut | Description |
| -------- | ----------- |
| `Shift + ?` | Show keyboard shortcuts help modal |
| `Escape` | Close modal or cancel current operation |

## Using Keyboard Shortcuts

### Viewing All Shortcuts

Press `Shift + ?` at any time to display a modal with all available keyboard shortcuts.

### Notes on Shortcuts

- Shortcuts are disabled when typing in input fields or text areas
- `Ctrl` key refers to `Cmd` on macOS
- Shortcuts are case-insensitive

## Customizing Shortcuts

Developers can customize shortcuts by modifying the `keyboardShortcuts.ts` utility file:

```typescript
import { createCustomShortcut, registerShortcuts } from '@/utils/keyboardShortcuts';

// Create a custom shortcut
const myShortcut = createCustomShortcut(
  'k',
  'Custom action',
  () => console.log('Custom action triggered'),
  { ctrlKey: true }
);

// Add to existing shortcuts
const customShortcuts = {
  ...defaultShortcuts,
  custom: [myShortcut]
};

// Register shortcuts
const cleanup = registerShortcuts(customShortcuts);
```

## Accessibility

Keyboard shortcuts improve accessibility by allowing users to:

- Navigate without a mouse
- Perform operations quickly
- Access features efficiently

## Browser Compatibility

Keyboard shortcuts work in all modern browsers:

- Chrome/Edge 90+
- Firefox 88+
- Safari 14+
- Opera 76+

## Tips

1. **Learn gradually**: Start with navigation shortcuts, then move to operations
2. **Practice**: Use shortcuts regularly to build muscle memory
3. **Check availability**: Press `Shift + ?` to see all shortcuts
4. **Combine with mouse**: Use shortcuts alongside mouse interactions for maximum efficiency
