/**
 * Keyboard shortcuts utility for HomeLab Dashboard
 */

export interface KeyboardShortcut {
  key: string;
  ctrlKey?: boolean;
  shiftKey?: boolean;
  altKey?: boolean;
  metaKey?: boolean;
  description: string;
  action: () => void;
}

export type ShortcutCategory = 
  | 'navigation'
  | 'operations'
  | 'general'
  | 'accessibility';

export interface CategorizedShortcuts {
  [category: string]: KeyboardShortcut[];
}

/**
 * Default keyboard shortcuts for the application
 */
export const defaultShortcuts: CategorizedShortcuts = {
  navigation: [
    {
      key: 'd',
      ctrlKey: true,
      description: 'Go to Dashboard',
      action: () => window.location.href = '/'
    },
    {
      key: 'p',
      ctrlKey: true,
      description: 'Go to Deployment page',
      action: () => window.location.href = '/deployment'
    },
    {
      key: 'v',
      ctrlKey: true,
      description: 'Go to VPN Management',
      action: () => window.location.href = '/vpn'
    },
    {
      key: 'n',
      ctrlKey: true,
      description: 'Go to NAT Gateway',
      action: () => window.location.href = '/nat'
    },
    {
      key: 's',
      ctrlKey: true,
      description: 'Go to Settings',
      action: () => window.location.href = '/settings'
    }
  ],
  operations: [
    {
      key: 'r',
      ctrlKey: true,
      description: 'Refresh current page',
      action: () => window.location.reload()
    },
    {
      key: 'e',
      ctrlKey: true,
      shiftKey: true,
      description: 'Export logs',
      action: () => {
        const event = new CustomEvent('export-logs');
        window.dispatchEvent(event);
      }
    }
  ],
  general: [
    {
      key: '?',
      shiftKey: true,
      description: 'Show keyboard shortcuts help',
      action: () => {
        const event = new CustomEvent('show-shortcuts-modal');
        window.dispatchEvent(event);
      }
    },
    {
      key: 't',
      ctrlKey: true,
      shiftKey: true,
      description: 'Toggle dark mode',
      action: () => {
        const event = new CustomEvent('toggle-theme');
        window.dispatchEvent(event);
      }
    },
    {
      key: 'Escape',
      description: 'Close modal/cancel operation',
      action: () => {
        const event = new CustomEvent('escape-pressed');
        window.dispatchEvent(event);
      }
    }
  ],
  accessibility: [
    {
      key: 'h',
      ctrlKey: true,
      description: 'Go to help/documentation',
      action: () => window.location.href = '/docs'
    }
  ]
};

/**
 * Checks if a keyboard event matches a shortcut
 */
function matchesShortcut(event: KeyboardEvent, shortcut: KeyboardShortcut): boolean {
  return (
    event.key.toLowerCase() === shortcut.key.toLowerCase() &&
    !!event.ctrlKey === !!shortcut.ctrlKey &&
    !!event.shiftKey === !!shortcut.shiftKey &&
    !!event.altKey === !!shortcut.altKey &&
    !!event.metaKey === !!shortcut.metaKey
  );
}

/**
 * Registers keyboard shortcuts
 */
export function registerShortcuts(
  shortcuts: CategorizedShortcuts = defaultShortcuts
): () => void {
  const handler = (event: KeyboardEvent) => {
    // Don't trigger shortcuts when typing in input fields
    const target = event.target as HTMLElement;
    if (
      target.tagName === 'INPUT' ||
      target.tagName === 'TEXTAREA' ||
      target.isContentEditable
    ) {
      return;
    }

    // Find and execute matching shortcut
    for (const category of Object.values(shortcuts)) {
      for (const shortcut of category) {
        if (matchesShortcut(event, shortcut)) {
          event.preventDefault();
          shortcut.action();
          break;
        }
      }
    }
  };

  document.addEventListener('keydown', handler);

  // Return cleanup function
  return () => {
    document.removeEventListener('keydown', handler);
  };
}

/**
 * Formats a shortcut as a readable string
 */
export function formatShortcut(shortcut: KeyboardShortcut): string {
  const parts: string[] = [];

  if (shortcut.ctrlKey) parts.push('Ctrl');
  if (shortcut.shiftKey) parts.push('Shift');
  if (shortcut.altKey) parts.push('Alt');
  if (shortcut.metaKey) parts.push('Cmd');

  parts.push(shortcut.key.toUpperCase());

  return parts.join(' + ');
}

/**
 * React component to display keyboard shortcuts help modal
 */
export function getShortcutsHelpContent(): string {
  let html = '<div class="shortcuts-help">';
  html += '<h2 class="text-2xl font-bold mb-4">Keyboard Shortcuts</h2>';

  const categoryTitles: Record<string, string> = {
    navigation: '🧭 Navigation',
    operations: '⚡ Operations',
    general: '🔧 General',
    accessibility: '♿ Accessibility'
  };

  for (const [category, shortcuts] of Object.entries(defaultShortcuts)) {
    html += `<div class="mb-6">`;
    html += `<h3 class="text-lg font-semibold mb-3">${categoryTitles[category] || category}</h3>`;
    html += `<div class="space-y-2">`;

    for (const shortcut of shortcuts) {
      const keys = formatShortcut(shortcut);
      html += `
        <div class="flex items-center justify-between p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded">
          <span class="text-gray-700 dark:text-gray-300">${shortcut.description}</span>
          <kbd class="px-3 py-1 bg-gray-200 dark:bg-gray-600 rounded text-sm font-mono">${keys}</kbd>
        </div>
      `;
    }

    html += `</div></div>`;
  }

  html += '</div>';
  return html;
}

/**
 * Gets all shortcuts as a flat array
 */
export function getAllShortcuts(): KeyboardShortcut[] {
  const allShortcuts: KeyboardShortcut[] = [];
  
  for (const shortcuts of Object.values(defaultShortcuts)) {
    allShortcuts.push(...shortcuts);
  }
  
  return allShortcuts;
}

/**
 * Checks if a specific shortcut key combination is available
 */
export function isShortcutAvailable(
  key: string,
  modifiers: {
    ctrlKey?: boolean;
    shiftKey?: boolean;
    altKey?: boolean;
    metaKey?: boolean;
  }
): boolean {
  const allShortcuts = getAllShortcuts();
  
  return !allShortcuts.some(shortcut =>
    shortcut.key.toLowerCase() === key.toLowerCase() &&
    !!shortcut.ctrlKey === !!modifiers.ctrlKey &&
    !!shortcut.shiftKey === !!modifiers.shiftKey &&
    !!shortcut.altKey === !!modifiers.altKey &&
    !!shortcut.metaKey === !!modifiers.metaKey
  );
}

/**
 * Creates a custom shortcut
 */
export function createCustomShortcut(
  key: string,
  description: string,
  action: () => void,
  modifiers?: {
    ctrlKey?: boolean;
    shiftKey?: boolean;
    altKey?: boolean;
    metaKey?: boolean;
  }
): KeyboardShortcut {
  return {
    key,
    description,
    action,
    ...modifiers
  };
}
