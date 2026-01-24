// GET /api/v1/health
// Health check endpoint for monitoring

import type { APIRoute } from 'astro';
import { supabase } from '../../../lib/supabase';

export const prerender = false;

export const GET: APIRoute = async () => {
    const startTime = Date.now();

    // Check database connection
    let dbStatus = 'ok';
    try {
        const { error } = await supabase
            .from('product_codes')
            .select('id')
            .limit(1)
            .single();

        if (error && error.code !== 'PGRST116') { // PGRST116 = no rows
            dbStatus = 'error';
        }
    } catch {
        dbStatus = 'error';
    }

    const latency = Date.now() - startTime;

    return new Response(JSON.stringify({
        status: dbStatus === 'ok' ? 'healthy' : 'degraded',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        latency_ms: latency,
        services: {
            database: dbStatus,
            api: 'ok',
        },
    }), {
        status: dbStatus === 'ok' ? 200 : 503,
        headers: {
            'Content-Type': 'application/json',
            'Cache-Control': 'no-cache',
        },
    });
};
