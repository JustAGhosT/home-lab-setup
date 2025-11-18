/**
 * Utility functions for PowerShell command execution with retry and timeout support
 */

import { invoke } from './invoke';
import { RetryConfig, OperationTimeouts } from '../constants/commands';

/**
 * Sleep for a specified duration
 * @param ms - Milliseconds to sleep
 */
const sleep = (ms: number): Promise<void> => 
  new Promise(resolve => setTimeout(resolve, ms));

/**
 * Executes a command with retry logic
 * @param command - Command to execute
 * @param args - Command arguments
 * @param maxAttempts - Maximum number of retry attempts
 * @param onRetry - Optional callback for retry events
 * @returns Promise resolving to command output
 */
export async function invokeWithRetry(
  command: string,
  args: string[],
  maxAttempts: number = RetryConfig.maxAttempts,
  onRetry?: (attempt: number, error: Error) => void
): Promise<string> {
  let lastError: Error | null = null;
  
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await invoke(command, args);
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));
      
      if (attempt < maxAttempts) {
        const delay = RetryConfig.initialDelay * Math.pow(RetryConfig.backoffMultiplier, attempt - 1);
        
        if (onRetry) {
          onRetry(attempt, lastError);
        }
        
        console.warn(
          `Command failed on attempt ${attempt}/${maxAttempts}. Retrying in ${delay}ms...`,
          lastError.message
        );
        
        await sleep(delay);
      }
    }
  }
  
  throw new Error(
    `Command failed after ${maxAttempts} attempts: ${lastError?.message || 'Unknown error'}`
  );
}

/**
 * Executes a command with a timeout
 * @param command - Command to execute
 * @param args - Command arguments
 * @param timeoutMs - Timeout in milliseconds
 * @returns Promise resolving to command output
 */
export async function invokeWithTimeout(
  command: string,
  args: string[],
  timeoutMs: number = OperationTimeouts.medium
): Promise<string> {
  return Promise.race([
    invoke(command, args),
    new Promise<string>((_, reject) =>
      setTimeout(
        () => reject(new Error(`Operation timed out after ${timeoutMs}ms`)),
        timeoutMs
      )
    )
  ]);
}

/**
 * Executes a command with both retry and timeout logic
 * @param command - Command to execute
 * @param args - Command arguments
 * @param options - Configuration options
 * @returns Promise resolving to command output
 */
export async function invokeWithRetryAndTimeout(
  command: string,
  args: string[],
  options: {
    maxAttempts?: number;
    timeoutMs?: number;
    onRetry?: (attempt: number, error: Error) => void;
  } = {}
): Promise<string> {
  const {
    maxAttempts = RetryConfig.maxAttempts,
    timeoutMs = OperationTimeouts.medium,
    onRetry
  } = options;
  
  return invokeWithRetry(
    command,
    args,
    maxAttempts,
    async (attempt, error) => {
      if (onRetry) {
        onRetry(attempt, error);
      }
    }
  );
}

/**
 * Progress callback type for long-running operations
 */
export type ProgressCallback = (progress: {
  percentage: number;
  message: string;
  step?: string;
}) => void;

/**
 * Executes a long-running command with simulated progress updates
 * @param command - Command to execute
 * @param args - Command arguments
 * @param estimatedDuration - Estimated duration in milliseconds
 * @param onProgress - Callback for progress updates
 * @returns Promise resolving to command output
 */
export async function invokeWithProgress(
  command: string,
  args: string[],
  estimatedDuration: number,
  onProgress: ProgressCallback
): Promise<string> {
  const updateInterval = 2000; // Update every 2 seconds
  const totalUpdates = Math.floor(estimatedDuration / updateInterval);
  let currentUpdate = 0;
  
  // Start progress updates
  const progressInterval = setInterval(() => {
    currentUpdate++;
    const percentage = Math.min((currentUpdate / totalUpdates) * 100, 95); // Cap at 95% until complete
    
    onProgress({
      percentage,
      message: `Processing... ${percentage.toFixed(0)}% complete`,
      step: `Step ${currentUpdate} of ${totalUpdates}`
    });
  }, updateInterval);
  
  try {
    const result = await invoke(command, args);
    
    // Clear interval and set to 100%
    clearInterval(progressInterval);
    onProgress({
      percentage: 100,
      message: 'Operation completed successfully',
      step: 'Complete'
    });
    
    return result;
  } catch (error) {
    clearInterval(progressInterval);
    throw error;
  }
}

/**
 * Simple in-memory cache for command results
 */
class CommandCache {
  private cache: Map<string, { result: string; timestamp: number }> = new Map();
  private defaultTtl: number = 60000; // 1 minute default TTL
  
  /**
   * Gets a cached result if it exists and is not expired
   * @param key - Cache key
   * @param ttl - Time to live in milliseconds
   * @returns Cached result or null
   */
  get(key: string, ttl: number = this.defaultTtl): string | null {
    const cached = this.cache.get(key);
    
    if (!cached) {
      return null;
    }
    
    const age = Date.now() - cached.timestamp;
    if (age > ttl) {
      this.cache.delete(key);
      return null;
    }
    
    return cached.result;
  }
  
  /**
   * Sets a cache entry
   * @param key - Cache key
   * @param result - Result to cache
   */
  set(key: string, result: string): void {
    this.cache.set(key, {
      result,
      timestamp: Date.now()
    });
  }
  
  /**
   * Clears the entire cache
   */
  clear(): void {
    this.cache.clear();
  }
  
  /**
   * Removes a specific cache entry
   * @param key - Cache key to remove
   */
  remove(key: string): void {
    this.cache.delete(key);
  }
}

// Export singleton instance
export const commandCache = new CommandCache();

/**
 * Executes a command with caching support
 * @param command - Command to execute
 * @param args - Command arguments
 * @param cacheKey - Unique cache key
 * @param cacheTtl - Cache time to live in milliseconds
 * @returns Promise resolving to command output
 */
export async function invokeWithCache(
  command: string,
  args: string[],
  cacheKey: string,
  cacheTtl: number = 60000
): Promise<string> {
  // Check cache first
  const cached = commandCache.get(cacheKey, cacheTtl);
  if (cached !== null) {
    console.log(`Cache hit for key: ${cacheKey}`);
    return cached;
  }
  
  // Execute command and cache result
  console.log(`Cache miss for key: ${cacheKey}, executing command`);
  const result = await invoke(command, args);
  commandCache.set(cacheKey, result);
  
  return result;
}
