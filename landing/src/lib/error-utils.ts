/**
 * KitTicker Error Handling Utilities
 * 
 * Standardized error handling for Supabase and general app errors.
 */

// ============================================
// Types
// ============================================

export interface AppError {
    code: string;
    message: string;
    details?: Record<string, unknown>;
    timestamp: string;
}

export interface RetryConfig {
    maxRetries: number;
    delayMs: number;
    backoffMultiplier: number;
}

// ============================================
// Error Handling
// ============================================

/**
 * Convert unknown error to standardized AppError
 */
export function handleError(error: unknown): AppError {
    const timestamp = new Date().toISOString();

    // Supabase error
    if (error && typeof error === 'object') {
        if ('code' in error && 'message' in error) {
            return {
                code: String(error.code),
                message: String(error.message),
                details: error as Record<string, unknown>,
                timestamp,
            };
        }

        // Generic error with message
        if ('message' in error) {
            return {
                code: 'UNKNOWN',
                message: String(error.message),
                timestamp,
            };
        }
    }

    // Fallback
    return {
        code: 'UNKNOWN',
        message: 'An unexpected error occurred',
        timestamp,
    };
}

// ============================================
// Retry Logic
// ============================================

const DEFAULT_RETRY_CONFIG: RetryConfig = {
    maxRetries: 3,
    delayMs: 1000,
    backoffMultiplier: 2,
};

/**
 * Execute a function with retry logic for transient failures
 */
export async function withRetry<T>(
    fn: () => Promise<T>,
    config: Partial<RetryConfig> = {}
): Promise<T> {
    const { maxRetries, delayMs, backoffMultiplier } = {
        ...DEFAULT_RETRY_CONFIG,
        ...config,
    };

    let lastError: unknown;
    let currentDelay = delayMs;

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
        try {
            return await fn();
        } catch (error) {
            lastError = error;

            // Don't retry on the last attempt
            if (attempt < maxRetries) {
                await sleep(currentDelay);
                currentDelay *= backoffMultiplier;
            }
        }
    }

    throw lastError;
}

/**
 * Sleep for specified milliseconds
 */
function sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// ============================================
// Logging
// ============================================

export function logError(context: string, error: unknown): void {
    const appError = handleError(error);
    console.error(`[${context}] ${appError.code}: ${appError.message}`, appError.details || '');
}
