# Advanced Features Guide

This document describes the advanced features available in the HomeLab Dashboard application.

## Table of Contents

- [Retry Mechanism](#retry-mechanism)
- [Operation Timeouts](#operation-timeouts)
- [Progress Tracking](#progress-tracking)
- [Result Caching](#result-caching)
- [Log Export](#log-export)
- [Dark Mode](#dark-mode)

## Retry Mechanism

The retry mechanism automatically retries failed operations with exponential backoff.

### Retry Usage

```typescript
import { invokeWithRetry } from '@/utils/commandUtils';
import { DeploymentCommands } from '@/constants/commands';

// Execute with automatic retry
const result = await invokeWithRetry(
  'pwsh',
  ['-Command', DeploymentCommands.deployNetwork()],
  3, // max attempts
  (attempt, error) => {
    console.log(`Retry attempt ${attempt}:`, error.message);
  }
);
```

### Configuration

Default retry configuration (can be customized):

```typescript
{
  maxAttempts: 3,
  initialDelay: 1000,      // 1 second
  backoffMultiplier: 2     // Delay doubles each retry
}
```

### Retry Delays

- Attempt 1: Immediate
- Attempt 2: After 1 second
- Attempt 3: After 2 seconds
- Attempt 4: After 4 seconds (if maxAttempts > 3)

## Operation Timeouts

Prevent long-running operations from hanging indefinitely.

### Timeout Usage

```typescript
import { invokeWithTimeout } from '@/utils/commandUtils';
import { OperationTimeouts } from '@/constants/commands';

// Execute with timeout
const result = await invokeWithTimeout(
  'pwsh',
  ['-Command', 'Get-AzureStatus'],
  OperationTimeouts.medium // 2 minutes
);
```

### Timeout Options

```typescript
{
  short: 30000,      // 30 seconds
  medium: 120000,    // 2 minutes
  long: 900000,      // 15 minutes
  veryLong: 2700000  // 45 minutes
}
```

### Combining Retry and Timeout

```typescript
import { invokeWithRetryAndTimeout } from '@/utils/commandUtils';

const result = await invokeWithRetryAndTimeout(
  'pwsh',
  ['-Command', 'Deploy-Infrastructure'],
  {
    maxAttempts: 3,
    timeoutMs: OperationTimeouts.veryLong,
    onRetry: (attempt, error) => {
      console.log(`Retry ${attempt}:`, error);
    }
  }
);
```

## Progress Tracking

Track progress of long-running operations with visual feedback.

### Progress Usage

```typescript
import { invokeWithProgress } from '@/utils/commandUtils';

await invokeWithProgress(
  'pwsh',
  ['-Command', 'Deploy-VpnGateway'],
  2700000, // 45 minutes estimated
  (progress) => {
    console.log(`${progress.percentage.toFixed(0)}%: ${progress.message}`);
    // Update UI with progress.percentage
  }
);
```

### Progress Callback

The callback receives:

```typescript
{
  percentage: number;  // 0-100
  message: string;     // Status message
  step?: string;       // Current step description
}
```

## Result Caching

Cache command results to reduce redundant operations and improve performance.

### Caching Usage

```typescript
import { invokeWithCache, commandCache } from '@/utils/commandUtils';

// Execute with caching
const status = await invokeWithCache(
  'pwsh',
  ['-Command', 'Get-AzureConnectionStatus'],
  'azure-status',  // Cache key
  60000           // Cache for 1 minute
);

// Manual cache management
commandCache.clear();                    // Clear all cache
commandCache.remove('azure-status');     // Clear specific entry
```

### Cache Benefits

- Reduces API calls
- Improves response time
- Minimizes Azure costs
- Better user experience

### Cache Strategy

- Default TTL: 1 minute
- Automatically expires old entries
- In-memory storage (cleared on page refresh)

## Log Export

Export deployment logs in multiple formats for analysis and reporting.

### Export Formats

#### Text Export

```typescript
import { exportLogsAsText } from '@/utils/logExporter';

// Export as plain text
exportLogsAsText(logs, 'deployment-logs.txt');
```

#### JSON Export

```typescript
import { exportLogsAsJson } from '@/utils/logExporter';

// Export as JSON for programmatic processing
exportLogsAsJson(logEntries, 'deployment-logs.json');
```

#### CSV Export

```typescript
import { exportLogsAsCsv } from '@/utils/logExporter';

// Export as CSV for spreadsheet analysis
exportLogsAsCsv(logEntries, 'deployment-logs.csv');
```

### Log Filtering

Filter logs before exporting:

```typescript
import { 
  filterLogsByLevel, 
  filterLogsByDateRange,
  searchLogs 
} from '@/utils/logExporter';

// Filter by level
const errors = filterLogsByLevel(logs, ['error']);

// Filter by date
const today = filterLogsByDateRange(
  logs,
  new Date('2024-01-01'),
  new Date('2024-01-02')
);

// Search logs
const results = searchLogs(logs, 'deployment failed');
```

### Log Summary

Generate summary statistics:

```typescript
import { generateLogSummary } from '@/utils/logExporter';

const summary = generateLogSummary(logs);
console.log(`Total: ${summary.total}`);
console.log(`Errors: ${summary.byLevel.error || 0}`);
console.log(`Operations: ${Object.keys(summary.byOperation).length}`);
```

## Dark Mode

Toggle between light and dark themes with system preference support.

### Features

- Manual theme switching
- System preference detection
- Persistent preference storage
- Smooth transitions
- Theme-aware components

### Dark Mode Usage

#### Initialize Theme

```typescript
import { initializeTheme } from '@/utils/themeUtils';

// Call on app startup
initializeTheme();
```

#### Toggle Theme

```typescript
import { toggleTheme } from '@/utils/themeUtils';

// Toggle between light and dark
const newTheme = toggleTheme();
```

#### Set Specific Theme

```typescript
import { saveTheme, applyTheme, resolveTheme } from '@/utils/themeUtils';

// Set to dark mode
saveTheme('dark');
applyTheme('dark');

// Set to system preference
saveTheme('system');
applyTheme(resolveTheme('system'));
```

#### Watch System Changes

```typescript
import { watchSystemTheme, applyTheme } from '@/utils/themeUtils';

// Automatically update when system theme changes
const cleanup = watchSystemTheme((theme) => {
  applyTheme(theme);
});

// Call cleanup when component unmounts
cleanup();
```

### Theme-Aware Styling

Use theme-specific classes:

```typescript
import { getThemeClasses } from '@/utils/themeUtils';

const theme = getSystemTheme();
const classes = getThemeClasses(theme);

// Apply classes
<div className={classes.card}>
  <button className={classes.button}>Click me</button>
</div>
```

### CSS Classes

The dark mode system uses Tailwind's dark mode support:

```css
/* Automatically handled by themeUtils */
.dark .bg-white { background-color: #1f2937; }
.dark .text-gray-900 { color: #f9fafb; }
```

## Best Practices

1. **Use retry for network operations**: API calls and Azure operations
2. **Set appropriate timeouts**: Match timeout to operation duration
3. **Cache read-only data**: Status checks, configuration data
4. **Export logs regularly**: Keep records of deployments
5. **Respect system theme**: Use 'system' as default theme preference
6. **Monitor cache size**: Clear cache periodically in long sessions

## Performance Tips

- Use caching for frequently accessed data
- Set shorter timeouts for quick operations
- Combine multiple operations when possible
- Export logs asynchronously to avoid UI blocking
- Preload theme preference on app start

## Troubleshooting

### Retry Not Working

- Check network connectivity
- Verify command syntax
- Increase max attempts for unstable connections

### Timeout Too Short

- Monitor operation duration
- Adjust timeout based on actual duration
- Use progress tracking for long operations

### Cache Not Clearing

- Manually call `commandCache.clear()`
- Check cache TTL settings
- Verify cache key uniqueness

### Theme Not Persisting

- Check localStorage availability
- Verify browser supports localStorage
- Check for private/incognito mode

### Logs Not Exporting

- Check browser download permissions
- Verify log data format
- Try different export format
