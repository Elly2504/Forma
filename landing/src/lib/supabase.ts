import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.PUBLIC_SUPABASE_URL || 'https://sjltydrpwavzrrmoaivt.supabase.co';
const supabaseAnonKey = import.meta.env.PUBLIC_SUPABASE_ANON_KEY || 'sb_publishable_Opl1yKqUYnrsHFdW5_ONaA_KVlHKYDf';

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
        .ilike('code', normalizedCode)
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
