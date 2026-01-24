// GET /api/v1/dpp/:uid
// Lookup Digital Product Passport by UID

import type { APIRoute } from 'astro';
import { getDppByUid } from '../../../../lib/dpp';
import type { DPPLookupResponse } from '../../../../lib/api-types';

export const prerender = false;

export const GET: APIRoute = async ({ params, url }) => {
    const requestId = crypto.randomUUID();

    // Get UID from path or query
    const uid = params.uid || url.searchParams.get('uid');

    if (!uid) {
        return new Response(JSON.stringify({
            success: false,
            error: 'Missing UID parameter',
            request_id: requestId,
        }), {
            status: 400,
            headers: { 'Content-Type': 'application/json' },
        });
    }

    // DPP lookup is public (no API key required)
    // This allows QR code scanning by anyone
    const result = await getDppByUid(uid);

    if (!result.success || !result.dpp) {
        return new Response(JSON.stringify({
            success: false,
            error: 'DPP not found',
            request_id: requestId,
        }), {
            status: 404,
            headers: { 'Content-Type': 'application/json' },
        });
    }

    const response: DPPLookupResponse = {
        success: true,
        request_id: requestId,
        data: result.dpp,
    };

    return new Response(JSON.stringify(response), {
        status: 200,
        headers: {
            'Content-Type': 'application/json',
            'X-Request-ID': requestId,
            'Cache-Control': 'public, max-age=300', // Cache for 5 minutes
        },
    });
};
