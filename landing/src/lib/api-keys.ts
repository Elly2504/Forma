// KitTicker API Key Management
// Utilities for API key generation, validation, and quota management
// Uses Web Crypto API for browser/edge compatibility

import { supabase } from './supabase';
import type { ApiKey, ApiTier } from './api-types';

// ============================================
// Crypto Helpers (Web Crypto API)
// ============================================

/**
 * Generate cryptographically secure random hex string
 */
function generateRandomHex(bytes: number): string {
    const array = new Uint8Array(bytes);
    crypto.getRandomValues(array);
    return Array.from(array, b => b.toString(16).padStart(2, '0')).join('');
}

/**
 * Hash a string using SHA-256 (Web Crypto API)
 */
async function sha256(message: string): Promise<string> {
    const msgBuffer = new TextEncoder().encode(message);
    const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

// ============================================
// API Key Generation
// ============================================

/**
 * Generate a new API key
 * Format: kt_live_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX (40 chars total)
 */
export async function generateApiKey(): Promise<{ key: string; prefix: string; hash: string }> {
    const randomPart = generateRandomHex(24); // 48 hex chars
    const key = `kt_live_${randomPart}`;
    const prefix = key.substring(0, 12); // kt_live_XXXX
    const hash = await sha256(key);

    return { key, prefix, hash };
}

/**
 * Hash an API key for storage
 */
export async function hashApiKey(key: string): Promise<string> {
    return sha256(key);
}

// ============================================
// API Key Validation
// ============================================

export interface ValidateKeyResult {
    valid: boolean;
    apiKey?: ApiKey;
    error?: string;
}

/**
 * Validate an API key from request header
 */
export async function validateApiKey(authHeader: string | null): Promise<ValidateKeyResult> {
    if (!authHeader) {
        return { valid: false, error: 'Missing Authorization header' };
    }

    // Support both "Bearer kt_live_..." and "kt_live_..." formats
    const key = authHeader.startsWith('Bearer ')
        ? authHeader.substring(7)
        : authHeader;

    if (!key.startsWith('kt_live_')) {
        return { valid: false, error: 'Invalid API key format' };
    }

    const keyHash = await hashApiKey(key);

    const { data, error } = await supabase
        .from('api_keys')
        .select('*')
        .eq('key_hash', keyHash)
        .eq('is_active', true)
        .single();

    if (error || !data) {
        return { valid: false, error: 'Invalid or inactive API key' };
    }

    return { valid: true, apiKey: data as ApiKey };
}

// ============================================
// Rate Limiting & Quota Management
// ============================================

export interface QuotaCheckResult {
    allowed: boolean;
    remaining: number;
    tier: ApiTier;
    resetDate?: Date;
    error?: string;
}

/**
 * Check if API key has remaining quota
 */
export async function checkQuota(apiKey: ApiKey): Promise<QuotaCheckResult> {
    // Enterprise tier has unlimited quota
    if (apiKey.tier === 'enterprise') {
        return {
            allowed: true,
            remaining: -1,
            tier: apiKey.tier
        };
    }

    if (apiKey.usage_this_month >= apiKey.monthly_quota) {
        // Calculate reset date (1st of next month)
        const now = new Date();
        const resetDate = new Date(now.getFullYear(), now.getMonth() + 1, 1);

        return {
            allowed: false,
            remaining: 0,
            tier: apiKey.tier,
            resetDate,
            error: `Monthly quota of ${apiKey.monthly_quota} requests exceeded`
        };
    }

    return {
        allowed: true,
        remaining: apiKey.monthly_quota - apiKey.usage_this_month,
        tier: apiKey.tier
    };
}

/**
 * Increment usage counter for an API key
 */
export async function incrementUsage(apiKeyId: string): Promise<void> {
    // Try to use the database function first
    try {
        await supabase.rpc('increment_api_key_usage', { key_id: apiKeyId });
    } catch {
        // Fallback: manual increment if RPC fails
        const { data } = await supabase
            .from('api_keys')
            .select('usage_this_month')
            .eq('id', apiKeyId)
            .single();

        if (data) {
            await supabase
                .from('api_keys')
                .update({
                    usage_this_month: (data.usage_this_month || 0) + 1,
                    last_used_at: new Date().toISOString()
                })
                .eq('id', apiKeyId);
        }
    }
}

// ============================================
// API Key CRUD Operations
// ============================================

/**
 * Create a new API key for a user
 */
export async function createApiKey(
    ownerEmail: string,
    tier: ApiTier = 'free',
    companyName?: string
): Promise<{ success: boolean; key?: string; error?: string }> {
    const { key, prefix, hash } = await generateApiKey();

    const tierLimits = {
        free: { rate_limit: 100, monthly_quota: 1000 },
        starter: { rate_limit: 500, monthly_quota: 5000 },
        business: { rate_limit: 2000, monthly_quota: 25000 },
        enterprise: { rate_limit: 10000, monthly_quota: 999999 },
    };

    const { error } = await supabase
        .from('api_keys')
        .insert({
            key_prefix: prefix,
            key_hash: hash,
            owner_email: ownerEmail,
            company_name: companyName,
            tier,
            rate_limit: tierLimits[tier].rate_limit,
            monthly_quota: tierLimits[tier].monthly_quota,
        });

    if (error) {
        return { success: false, error: error.message };
    }

    // Return the actual key - this is the ONLY time it's visible
    return { success: true, key };
}

/**
 * Revoke an API key
 */
export async function revokeApiKey(keyId: string): Promise<boolean> {
    const { error } = await supabase
        .from('api_keys')
        .update({ is_active: false })
        .eq('id', keyId);

    return !error;
}

/**
 * Get all API keys for a user (without the actual key, just metadata)
 */
export async function getUserApiKeys(ownerEmail: string): Promise<Partial<ApiKey>[]> {
    const { data, error } = await supabase
        .from('api_keys')
        .select('id, key_prefix, tier, monthly_quota, usage_this_month, is_active, created_at, last_used_at')
        .eq('owner_email', ownerEmail)
        .order('created_at', { ascending: false });

    if (error) return [];
    return data;
}

// ============================================
// Usage Logging
// ============================================

export async function logApiUsage(
    apiKeyId: string,
    endpoint: string,
    method: string,
    requestParams: Record<string, unknown>,
    responseStatus: number,
    latencyMs: number,
    cached: boolean = false,
    ipAddress?: string,
    userAgent?: string
): Promise<void> {
    await supabase.from('api_usage_logs').insert({
        api_key_id: apiKeyId,
        endpoint,
        method,
        request_params: requestParams,
        response_status: responseStatus,
        response_cached: cached,
        latency_ms: latencyMs,
        ip_address: ipAddress,
        user_agent: userAgent,
    });
}
