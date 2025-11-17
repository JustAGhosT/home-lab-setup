/**
 * Dark mode theme management utility
 */

export type Theme = 'light' | 'dark' | 'system';

const THEME_STORAGE_KEY = 'homelab-theme-preference';
const THEME_CLASS = 'dark';

/**
 * Gets the current theme preference from localStorage
 * @returns The stored theme preference or 'system' as default
 */
export function getStoredTheme(): Theme {
  if (typeof window === 'undefined') return 'system';
  
  const stored = localStorage.getItem(THEME_STORAGE_KEY);
  if (stored === 'light' || stored === 'dark' || stored === 'system') {
    return stored;
  }
  return 'system';
}

/**
 * Saves theme preference to localStorage
 * @param theme - Theme to save
 */
export function saveTheme(theme: Theme): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(THEME_STORAGE_KEY, theme);
}

/**
 * Gets the system's preferred color scheme
 * @returns 'dark' if system prefers dark mode, 'light' otherwise
 */
export function getSystemTheme(): 'light' | 'dark' {
  if (typeof window === 'undefined') return 'light';
  
  return window.matchMedia('(prefers-color-scheme: dark)').matches
    ? 'dark'
    : 'light';
}

/**
 * Resolves the actual theme to apply based on preference
 * @param theme - Theme preference
 * @returns Resolved theme ('light' or 'dark')
 */
export function resolveTheme(theme: Theme): 'light' | 'dark' {
  if (theme === 'system') {
    return getSystemTheme();
  }
  return theme;
}

/**
 * Applies the theme to the document
 * @param theme - Theme to apply
 */
export function applyTheme(theme: 'light' | 'dark'): void {
  if (typeof window === 'undefined') return;
  
  const root = document.documentElement;
  
  if (theme === 'dark') {
    root.classList.add(THEME_CLASS);
  } else {
    root.classList.remove(THEME_CLASS);
  }
}

/**
 * Initializes theme based on stored preference or system preference
 */
export function initializeTheme(): void {
  const storedTheme = getStoredTheme();
  const resolvedTheme = resolveTheme(storedTheme);
  applyTheme(resolvedTheme);
}

/**
 * Sets up a listener for system theme changes
 * @param callback - Callback to execute when system theme changes
 * @returns Cleanup function to remove the listener
 */
export function watchSystemTheme(callback: (theme: 'light' | 'dark') => void): () => void {
  if (typeof window === 'undefined') {
    return () => {};
  }
  
  const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
  
  const handler = (e: MediaQueryListEvent) => {
    callback(e.matches ? 'dark' : 'light');
  };
  
  // Modern browsers
  if (mediaQuery.addEventListener) {
    mediaQuery.addEventListener('change', handler);
    return () => mediaQuery.removeEventListener('change', handler);
  }
  
  // Fallback for older browsers
  mediaQuery.addListener(handler);
  return () => mediaQuery.removeListener(handler);
}

/**
 * React hook for theme management
 */
export function useTheme(): {
  theme: Theme;
  resolvedTheme: 'light' | 'dark';
  setTheme: (theme: Theme) => void;
} {
  // This would be a React hook in a real implementation
  // For now, providing a simplified version
  const theme = getStoredTheme();
  const resolvedTheme = resolveTheme(theme);
  
  const setTheme = (newTheme: Theme) => {
    saveTheme(newTheme);
    const resolved = resolveTheme(newTheme);
    applyTheme(resolved);
  };
  
  return {
    theme,
    resolvedTheme,
    setTheme
  };
}

/**
 * Toggles between light and dark themes
 * @returns The new theme
 */
export function toggleTheme(): 'light' | 'dark' {
  const currentTheme = getStoredTheme();
  const currentResolved = resolveTheme(currentTheme);
  const newTheme: 'light' | 'dark' = currentResolved === 'dark' ? 'light' : 'dark';
  
  saveTheme(newTheme);
  applyTheme(newTheme);
  
  return newTheme;
}

/**
 * CSS classes for different themes
 */
export const themeClasses = {
  light: {
    background: 'bg-white',
    text: 'text-gray-900',
    border: 'border-gray-200',
    card: 'bg-white shadow-md',
    button: 'bg-blue-500 hover:bg-blue-600 text-white',
    input: 'bg-white border-gray-300 text-gray-900',
    link: 'text-blue-600 hover:text-blue-800'
  },
  dark: {
    background: 'bg-gray-900',
    text: 'text-gray-100',
    border: 'border-gray-700',
    card: 'bg-gray-800 shadow-xl',
    button: 'bg-blue-600 hover:bg-blue-700 text-white',
    input: 'bg-gray-800 border-gray-600 text-gray-100',
    link: 'text-blue-400 hover:text-blue-300'
  }
} as const;

/**
 * Gets theme-specific classes
 * @param theme - Current theme
 * @returns Object with theme-specific class names
 */
export function getThemeClasses(theme: 'light' | 'dark') {
  return themeClasses[theme];
}
