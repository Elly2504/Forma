// POST /api/v1/dpp/generate
// Generate Digital Product Passport for a verified product

import type { APIRoute } from 'astro';
import { supabase } from '../../../../lib/supabase';
import { validateApiKey, checkQuota, incrementUsage, logApiUsage } from '../../../../lib/api-keys';
import { createDpp, generateQrCodeUrl } from '../../../../lib/dpp';
import type { DPPGenerateRequest, DPPGenerateResponse } from '../../../../lib/api-types';

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

    // DPP generation requires business+ tier
    if (validation.apiKey.tier === 'free' || validation.apiKey.tier === 'starter') {
        return new Response(JSON.stringify({
            success: false,
            error: 'DPP generation requires Business tier or higher',
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
    let body: DPPGenerateRequest;
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

    if (!body.code || !body.owner_email) {
        return new Response(JSON.stringify({
            success: false,
            error: 'Missing required parameters: code, owner_email',
            request_id: requestId,
        }), {
            status: 400,
            headers: { 'Content-Type': 'application/json' },
        });
    }

    // Find the product code
    const { data: product, error: productError } = await supabase
        .from('product_codes')
        .select('*')
        .eq('code', body.code.toUpperCase())
        .single();

    if (productError || !product) {
        return new Response(JSON.stringify({
            success: false,
            error: 'Product code not found in database',
            request_id: requestId,
        }), {
            status: 404,
            headers: { 'Content-Type': 'application/json' },
        });
    }

    // Create the DPP
    const result = await createDpp({
        productCodeId: product.id,
        ownerEmail: body.owner_email,
        ownerName: body.owner_name,
        notes: body.notes,
        initialEvidence: product.verified ? [{
            type: 'code_match',
            confidence: 95,
            details: `Matched verified code ${product.code} in KitTicker database`,
            timestamp: new Date(),
        }] : undefined,
    });

    if (!result.success || !result.dpp) {
        return new Response(JSON.stringify({
            success: false,
            error: result.error || 'Failed to create DPP',
            request_id: requestId,
        }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' },
        });
    }

    // Generate QR code URL
    const qrCodeUrl = generateQrCodeUrl(result.dpp.uid);

    // Update the DPP with QR code URL
    await supabase
        .from('digital_passports')
        .update({ qr_code_url: qrCodeUrl })
        .eq('id', result.dpp.id);

    // Increment usage
    await incrementUsage(validation.apiKey.id);

    // Log the request
    const latency = Date.now() - startTime;
    await logApiUsage(
        validation.apiKey.id,
        '/v1/dpp/generate',
        'POST',
        { code: body.code },
        200,
        latency,
        false,
        request.headers.get('x-forwarded-for') || undefined,
        request.headers.get('user-agent') || undefined
    );

    const response: DPPGenerateResponse = {
        success: true,
        request_id: requestId,
        data: {
            uid: result.dpp.uid,
            qr_code_url: qrCodeUrl,
            verification_status: result.dpp.verification_status as 'pending' | 'verified',
            product_info: product,
        },
    };

    return new Response(JSON.stringify(response), {
        status: 201,
        headers: {
            'Content-Type': 'application/json',
            'X-RateLimit-Remaining': quota.remaining.toString(),
            'X-Request-ID': requestId,
        },
    });
};
