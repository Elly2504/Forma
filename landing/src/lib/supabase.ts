import { createClient } from '@supabase/supabase-js';

// Supabase configuration - hardcoded for client-side usage
const supabaseUrl = 'https://sjltydrpwavzrrmoaivt.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNqbHR5ZHJwd2F2enJybW9haXZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg2NDQwMzEsImV4cCI6MjA4NDIyMDAzMX0.nPdmhcj3GsvQ8xtE4i2CMptWb9kxMy1NKYyI1M7oT9k';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);



// Types for our database
export interface ProductCode {
    id: string;
    code: string;
    brand: string;
    team: string | null;
    season: string | null;
    kit_type: string | null;
    verified: boolean;
    lookup_count: number;
    created_at: string;
}

// Helper functions
export async function lookupProductCode(code: string): Promise<ProductCode | null> {
    const normalizedCode = code.trim().toUpperCase();

    const { data, error } = await supabase
        .from('product_codes')
        .select('*')
        .eq('code', normalizedCode)
        .single();

    if (error || !data) {
        return null;
    }

    // Increment lookup count
    await supabase
        .from('product_codes')
        .update({ lookup_count: (data.lookup_count || 0) + 1 })
        .eq('id', data.id);

    return data;
}

export async function getRecentlyCheckedCodes(limit: number = 5): Promise<ProductCode[]> {
    const { data, error } = await supabase
        .from('product_codes')
        .select('*')
        .order('lookup_count', { ascending: false })
        .limit(limit);

    if (error) {
        return [];
    }

    return data || [];
}
