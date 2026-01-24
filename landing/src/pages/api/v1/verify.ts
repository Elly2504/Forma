// POST /api/v1/verify
// Full verification endpoint with multi-signal authentication

import type { APIRoute } from 'astro';
import { validateApiKey, checkQuota, incrementUsage, logApiUsage } from '../../../lib/api-keys';
import { verifyProductCode } from '../../../lib/verifier';
import { crossValidateCodeVsVisual } from '../../../lib/dpp';
import type { FullVerifyRequest, FullVerifyResponse } from '../../../lib/api-types';

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
    let body: FullVerifyRequest;
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

    if (!body.code) {
        return new Response(JSON.stringify({
            success: false,
            error: 'Missing required parameter: code',
            request_id: requestId,
        }), {
            status: 400,
            headers: { 'Content-Type': 'application/json' },
        });
    }

    // Run multi-signal verification
    const verificationResult = await verifyProductCode(body.code, { brandFilter: body.brand });

    // If visual attributes provided, run cross-validation (Data Defense)
    let crossValidation = null;
    if (body.visual_attributes) {
        crossValidation = await crossValidateCodeVsVisual(body.code, {
            primary_color: body.visual_attributes.primary_color,
            kit_type: body.visual_attributes.kit_type,
            brand: body.brand,
        });
    }

    // Map signals to API response format
    const evidence = verificationResult.signals.map(s => ({
        signal: s.id,
        weight: s.weight,
        passed: s.value === 'pass',
        details: s.evidence,
    }));

    // Add cross-validation to evidence if performed
    if (crossValidation) {
        evidence.push({
            signal: 'visual_cross_check',
            weight: 15,
            passed: crossValidation.passed,
            details: crossValidation.passed
                ? 'Visual attributes match expected values'
                : `Mismatches: ${crossValidation.mismatches.join(', ')}`,
        });
    }

    // Calculate final confidence
    let finalConfidence = verificationResult.confidenceScore;
    if (crossValidation) {
        if (!crossValidation.passed) {
            finalConfidence = Math.max(finalConfidence - 20, 10);
        } else {
            finalConfidence = Math.min(finalConfidence + 10, 100);
        }
    }

    // Map verdict to API format
    const verdictMap: Record<string, 'authentic' | 'likely_authentic' | 'uncertain' | 'suspicious' | 'fake'> = {
        'highly_likely_authentic': 'authentic',
        'probably_authentic': 'likely_authentic',
        'uncertain': 'uncertain',
        'suspicious': 'suspicious',
        'likely_fake': 'fake',
        'blacklisted': 'fake',
    };

    let verdict = verdictMap[verificationResult.verdict] || 'uncertain';

    // Override verdict if cross-validation detected issues
    if (crossValidation && !crossValidation.passed && crossValidation.mismatches.length >= 2) {
        verdict = 'suspicious';
    }

    // Build warnings array
    const warnings: string[] = [];
    if (verificationResult.blacklistMatch) {
        warnings.push(`⚠️ BLACKLISTED: ${verificationResult.blacklistMatch.reason}`);
    }

    // Increment usage
    await incrementUsage(validation.apiKey.id);

    // Log the request
    const latency = Date.now() - startTime;
    await logApiUsage(
        validation.apiKey.id,
        '/v1/verify',
        'POST',
        { code: body.code, has_visual: !!body.visual_attributes },
        200,
        latency,
        false,
        request.headers.get('x-forwarded-for') || undefined,
        request.headers.get('user-agent') || undefined
    );

    const response: FullVerifyResponse = {
        success: true,
        request_id: requestId,
        data: {
            verdict,
            confidence: finalConfidence,
            evidence,
            warnings: warnings.length > 0 ? warnings : undefined,
            product_info: verificationResult.matchedProduct || undefined,
        },
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
