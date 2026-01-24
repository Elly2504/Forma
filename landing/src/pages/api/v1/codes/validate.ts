// POST /api/v1/codes/validate
// Batch validation endpoint for B2B API

import type { APIRoute } from 'astro';
import { supabase } from '../../../../lib/supabase';
import { validateApiKey, checkQuota, incrementUsage, logApiUsage } from '../../../../lib/api-keys';
import type { BatchValidateRequest, BatchValidateResponse } from '../../../../lib/api-types';

export const prerender = false;

export const POST: APIRoute = async ({ request }) => {
    const startTime = Date.now();
    const requestId = crypto.randomUUID();

    // Get API key from header
    const authHeader = request.headers.get('Authorization');
    const validation = await validateApiKey(authHeader);

    if (!validation.valid || !validation.apiKey) {
        return new Response(JSON.stringify({
            success: false,
            error: validation.error || 'Invalid API key',
            request_id: requestId,
        }), {
            status: 401,
            headers: { 'Content-Type': 'application/json' },
        });
    }

    // Check tier (batch only for starter+)
    if (validation.apiKey.tier === 'free') {
        return new Response(JSON.stringify({
            success: false,
            error: 'Batch validation requires Starter tier or higher',
            request_id: requestId,
        }), {
            status: 403,
            headers: { 'Content-Type': 'application/json' },
        });
    }

    // Check quota
    const quota = await checkQuota(validation.apiKey);
    if (!quota.allowed) {
        return new Response(JSON.stringify({
            success: false,
            error: quota.error,
            request_id: requestId,
        }), {
            status: 429,
            headers: { 'Content-Type': 'application/json' },
        });
    }

    // Parse request body
    let body: BatchValidateRequest;
    try {
        body = await request.json();
    } catch {
        return new Response(JSON.stringify({
            success: false,
            error: 'Invalid JSON body',
            request_id: requestId,
        }), {
            status: 400,
            headers: { 'Content-Type': 'application/json' },
        });
    }

    if (!body.codes || !Array.isArray(body.codes) || body.codes.length === 0) {
        return new Response(JSON.stringify({
            success: false,
            error: 'Missing or invalid codes array',
            request_id: requestId,
        }), {
            status: 400,
            headers: { 'Content-Type': 'application/json' },
        });
    }

    // Limit batch size
    const maxBatch = validation.apiKey.tier === 'enterprise' ? 500 : 100;
    if (body.codes.length > maxBatch) {
        return new Response(JSON.stringify({
            success: false,
            error: `Batch size exceeds maximum of ${maxBatch}`,
            request_id: requestId,
        }), {
            status: 400,
            headers: { 'Content-Type': 'application/json' },
        });
    }

    // Normalize codes
    const normalizedCodes = body.codes.map(c => c.toUpperCase().trim());

    // Lookup all codes
    const { data: products, error: productError } = await supabase
        .from('product_codes')
        .select('code, brand, verified')
        .in('code', normalizedCodes);

    // Check blacklist
    const { data: blacklisted } = await supabase
        .from('blacklist_codes')
        .select('code')
        .in('code', normalizedCodes);

    const blacklistedCodes = new Set(blacklisted?.map(b => b.code) || []);
    const productMap = new Map(products?.map(p => [p.code, p]) || []);

    // Build results
    const results = normalizedCodes.map(code => {
        const product = productMap.get(code);
        return {
            code,
            found: !!product,
            verified: product?.verified || false,
            brand: product?.brand,
            blacklisted: blacklistedCodes.has(code),
        };
    });

    // Stats
    const stats = {
        total: normalizedCodes.length,
        found: results.filter(r => r.found).length,
        verified: results.filter(r => r.verified).length,
        blacklisted: results.filter(r => r.blacklisted).length,
    };

    // Increment usage (count each code as 1 request for quota)
    await incrementUsage(validation.apiKey.id);

    // Log the request
    const latency = Date.now() - startTime;
    await logApiUsage(
        validation.apiKey.id,
        '/v1/codes/validate',
        'POST',
        { code_count: body.codes.length },
        200,
        latency,
        false,
        request.headers.get('x-forwarded-for') || undefined,
        request.headers.get('user-agent') || undefined
    );

    const response: BatchValidateResponse = {
        success: true,
        results,
        stats,
        request_id: requestId,
    };

    return new Response(JSON.stringify(response), {
        status: 200,
        headers: {
            'Content-Type': 'application/json',
            'X-RateLimit-Remaining': quota.remaining.toString(),
            'X-Request-ID': requestId,
        },
    });
};
