/**
 * Utility functions for exporting and managing deployment logs
 */

/**
 * Log entry interface
 */
export interface LogEntry {
  timestamp: Date;
  operation: string;
  message: string;
  level: 'info' | 'warning' | 'error' | 'success';
}

/**
 * Exports logs to a downloadable text file
 * @param logs - Array of log entries or plain text
 * @param filename - Output filename
 */
export function exportLogsAsText(
  logs: string | LogEntry[],
  filename: string = `homelab-logs-${new Date().toISOString().replace(/[:.]/g, '-')}.txt`
): void {
  let content: string;
  
  if (typeof logs === 'string') {
    content = logs;
  } else {
    content = logs
      .map(entry => {
        const timestamp = entry.timestamp.toISOString();
        return `[${timestamp}] [${entry.level.toUpperCase()}] ${entry.operation}: ${entry.message}`;
      })
      .join('\n');
  }
  
  downloadTextFile(content, filename);
}

/**
 * Exports logs as JSON
 * @param logs - Array of log entries
 * @param filename - Output filename
 */
export function exportLogsAsJson(
  logs: LogEntry[],
  filename: string = `homelab-logs-${new Date().toISOString().replace(/[:.]/g, '-')}.json`
): void {
  const content = JSON.stringify(logs, null, 2);
  downloadTextFile(content, filename);
}

/**
 * Exports logs as CSV
 * @param logs - Array of log entries
 * @param filename - Output filename
 */
export function exportLogsAsCsv(
  logs: LogEntry[],
  filename: string = `homelab-logs-${new Date().toISOString().replace(/[:.]/g, '-')}.csv`
): void {
  const headers = ['Timestamp', 'Level', 'Operation', 'Message'];
  const rows = logs.map(entry => [
    entry.timestamp.toISOString(),
    entry.level,
    entry.operation,
    entry.message.replace(/"/g, '""') // Escape quotes
  ]);
  
  const csvContent = [
    headers.join(','),
    ...rows.map(row => row.map(cell => `"${cell}"`).join(','))
  ].join('\n');
  
  downloadTextFile(csvContent, filename);
}

/**
 * Downloads text content as a file
 * @param content - File content
 * @param filename - Output filename
 */
function downloadTextFile(content: string, filename: string): void {
  const blob = new Blob([content], { type: 'text/plain;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  
  // Clean up the URL object
  setTimeout(() => URL.revokeObjectURL(url), 100);
}

/**
 * Formats log text with ANSI color codes removed
 * @param text - Raw log text
 * @returns Cleaned text
 */
export function cleanLogText(text: string): string {
  // Remove ANSI color codes
  return text.replace(/\x1b\[[0-9;]*m/g, '');
}

/**
 * Searches logs for a specific term
 * @param logs - Array of log entries or text
 * @param searchTerm - Term to search for
 * @returns Filtered logs
 */
export function searchLogs(
  logs: string | LogEntry[],
  searchTerm: string
): string | LogEntry[] {
  const term = searchTerm.toLowerCase();
  
  if (typeof logs === 'string') {
    return logs
      .split('\n')
      .filter(line => line.toLowerCase().includes(term))
      .join('\n');
  }
  
  return logs.filter(entry =>
    entry.operation.toLowerCase().includes(term) ||
    entry.message.toLowerCase().includes(term)
  );
}

/**
 * Filters logs by level
 * @param logs - Array of log entries
 * @param levels - Levels to include
 * @returns Filtered logs
 */
export function filterLogsByLevel(
  logs: LogEntry[],
  levels: LogEntry['level'][]
): LogEntry[] {
  return logs.filter(entry => levels.includes(entry.level));
}

/**
 * Filters logs by date range
 * @param logs - Array of log entries
 * @param startDate - Start date (inclusive)
 * @param endDate - End date (inclusive)
 * @returns Filtered logs
 */
export function filterLogsByDateRange(
  logs: LogEntry[],
  startDate: Date,
  endDate: Date
): LogEntry[] {
  return logs.filter(
    entry => entry.timestamp >= startDate && entry.timestamp <= endDate
  );
}

/**
 * Parses plain text logs into structured log entries
 * @param text - Plain text logs
 * @returns Array of log entries
 */
export function parseLogsFromText(text: string): LogEntry[] {
  const lines = text.split('\n');
  const entries: LogEntry[] = [];
  
  // Simple pattern matching for structured logs
  // Expected format: [timestamp] [LEVEL] operation: message
  // Security fix: Completely eliminate backtracking by using single space matches
  // This pattern is safe from ReDoS as it has no overlapping quantifiers
  const logPattern = /^\[([^\]]*)\] \[([^\]]*)\] ([^:]*): (.*)$/;
  
  for (const line of lines) {
    const match = line.match(logPattern);
    if (match) {
      const [, timestamp, level, operation, message] = match;
      entries.push({
        timestamp: new Date(timestamp),
        level: level.toLowerCase() as LogEntry['level'],
        operation: operation.trim(),
        message: message.trim()
      });
    } else if (line.trim()) {
      // Fallback for unstructured lines
      entries.push({
        timestamp: new Date(),
        level: 'info',
        operation: 'Unknown',
        message: line.trim()
      });
    }
  }
  
  return entries;
}

/**
 * Generates a summary report from logs
 * @param logs - Array of log entries
 * @returns Summary object
 */
export function generateLogSummary(logs: LogEntry[]): {
  total: number;
  byLevel: Record<string, number>;
  byOperation: Record<string, number>;
  firstEntry?: Date;
  lastEntry?: Date;
} {
  const summary = {
    total: logs.length,
    byLevel: {} as Record<string, number>,
    byOperation: {} as Record<string, number>,
    firstEntry: logs.length > 0 ? logs[0].timestamp : undefined,
    lastEntry: logs.length > 0 ? logs[logs.length - 1].timestamp : undefined
  };
  
  for (const entry of logs) {
    // Count by level
    summary.byLevel[entry.level] = (summary.byLevel[entry.level] || 0) + 1;
    
    // Count by operation
    summary.byOperation[entry.operation] = 
      (summary.byOperation[entry.operation] || 0) + 1;
  }
  
  return summary;
}
