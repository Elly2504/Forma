// GET /api/v1/codes/lookup
// Product code lookup endpoint for B2B API

import type { APIRoute } from 'astro';
import { supabase } from '../../../../lib/supabase';
import { validateApiKey, checkQuota, incrementUsage, logApiUsage } from '../../../../lib/api-keys';
import type { CodeLookupResponse } from '../../../../lib/api-types';

export const prerender = false;

export const GET: APIRoute = async ({ request, url }) => {
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

    // Check quota
    const quota = await checkQuota(validation.apiKey);
    if (!quota.allowed) {
        return new Response(JSON.stringify({
            success: false,
            error: quota.error,
            request_id: requestId,
            quota: {
                remaining: quota.remaining,
                reset_date: quota.resetDate,
            },
        }), {
            status: 429,
            headers: { 'Content-Type': 'application/json' },
        });
    }

    // Get query parameters
    const code = url.searchParams.get('code');
    const includePrice = url.searchParams.get('include_price') === 'true';
    const includeVisual = url.searchParams.get('include_visual') === 'true';

    if (!code) {
        return new Response(JSON.stringify({
            success: false,
            error: 'Missing required parameter: code',
            request_id: requestId,
        }), {
            status: 400,
            headers: { 'Content-Type': 'application/json' },
        });
    }

    // Lookup product code
    const { data: product, error } = await supabase
        .from('product_codes')
        .select('*')
        .eq('code', code.toUpperCase())
        .single();

    // Increment usage
    await incrementUsage(validation.apiKey.id);

    // Log the request
    const latency = Date.now() - startTime;
    await logApiUsage(
        validation.apiKey.id,
        '/v1/codes/lookup',
        'GET',
        { code, includePrice, includeVisual },
        product ? 200 : 404,
        latency,
        false,
        request.headers.get('x-forwarded-for') || undefined,
        request.headers.get('user-agent') || undefined
    );

    if (error || !product) {
        return new Response(JSON.stringify({
            success: false,
            error: 'Product code not found',
            request_id: requestId,
            cached: false,
        }), {
            status: 404,
            headers: { 'Content-Type': 'application/json' },
        });
    }

    // Increment lookup count
    await supabase.rpc('increment_api_lookup', { p_code: code });

    // Build response based on tier
    const tier = validation.apiKey.tier;
    const response: CodeLookupResponse = {
        success: true,
        cached: false,
        request_id: requestId,
        data: {
            code: product.code,
            brand: product.brand,
            team: product.team,
            season: product.season,
            kit_type: product.kit_type,
            variant: product.variant,
            verified: product.verified,
        },
    };

    // Add image URLs for starter+ tiers
    if (tier !== 'free' && product.image_url) {
        response.data!.image_url = product.image_url;
        response.data!.thumbnail_url = product.thumbnail_url;
    }

    // Add pricing for business+ tiers
    if ((tier === 'business' || tier === 'enterprise') && includePrice && product.estimated_price_min) {
        response.data!.estimated_price = {
            min: product.estimated_price_min,
            max: product.estimated_price_max,
            currency: product.price_currency || 'GBP',
            confidence: product.price_confidence || 'low',
            last_updated: product.last_price_update,
        };
    }

    // Add visual attributes for verification
    if (includeVisual && product.primary_color) {
        response.data!.visual_attributes = {
            primary_color: product.primary_color,
            secondary_color: product.secondary_color,
            pattern: product.pattern,
        };
    }

    return new Response(JSON.stringify(response), {
        status: 200,
        headers: {
            'Content-Type': 'application/json',
            'X-RateLimit-Remaining': quota.remaining.toString(),
            'X-Request-ID': requestId,
        },
    });
};
