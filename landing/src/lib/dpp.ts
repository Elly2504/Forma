// KitTicker Digital Product Passport (DPP) Module
// Proxy DPP for vintage items (1980-2026)

import { supabase } from './supabase';
import type { DigitalProductPassport, ProductCode, VerificationEvidence } from './api-types';

// ============================================
// UID Generation
// ============================================

/**
 * Generate a unique DPP UID
 * Format: KT-YYYY-XXXXXX
 */
export function generateDppUid(): string {
    const year = new Date().getFullYear();
    const randomPart = Math.random().toString(36).substring(2, 8).toUpperCase();
    return `KT-${year}-${randomPart}`;
}

// ============================================
// DPP Creation
// ============================================

export interface CreateDppOptions {
    productCodeId: string;
    ownerEmail: string;
    ownerName?: string;
    notes?: string;
    initialEvidence?: VerificationEvidence[];
}

export async function createDpp(options: CreateDppOptions): Promise<{
    success: boolean;
    dpp?: DigitalProductPassport;
    error?: string;
}> {
    const uid = generateDppUid();

    // Check for unique UID (extremely rare collision)
    let attempts = 0;
    let uniqueUid = uid;
    while (attempts < 3) {
        const { data: existing } = await supabase
            .from('digital_passports')
            .select('uid')
            .eq('uid', uniqueUid)
            .single();

        if (!existing) break;
        uniqueUid = generateDppUid();
        attempts++;
    }

    const { data, error } = await supabase
        .from('digital_passports')
        .insert({
            uid: uniqueUid,
            product_code_id: options.productCodeId,
            owner_email: options.ownerEmail,
            owner_name: options.ownerName,
            notes: options.notes,
            verification_status: options.initialEvidence ? 'verified' : 'pending',
            verification_evidence: options.initialEvidence || [],
            verification_date: options.initialEvidence ? new Date().toISOString() : null,
        })
        .select()
        .single();

    if (error) {
        return { success: false, error: error.message };
    }

    return { success: true, dpp: data };
}

// ============================================
// DPP Lookup
// ============================================

export async function getDppByUid(uid: string): Promise<{
    success: boolean;
    dpp?: DigitalProductPassport & { product: ProductCode };
    error?: string;
}> {
    const { data, error } = await supabase
        .from('digital_passports')
        .select(`
      *,
      product:product_codes(*)
    `)
        .eq('uid', uid)
        .single();

    if (error || !data) {
        return { success: false, error: 'DPP not found' };
    }

    return { success: true, dpp: data };
}

// ============================================
// Ownership Transfer
// ============================================

export async function transferDpp(
    uid: string,
    fromEmail: string,
    toEmail: string,
    toName?: string
): Promise<{ success: boolean; error?: string }> {
    // Get current DPP
    const { data: dpp, error: fetchError } = await supabase
        .from('digital_passports')
        .select('*')
        .eq('uid', uid)
        .eq('owner_email', fromEmail)
        .single();

    if (fetchError || !dpp) {
        return { success: false, error: 'DPP not found or you are not the owner' };
    }

    // Create transfer record
    const transferRecord = {
        from_email: fromEmail,
        to_email: toEmail,
        date: new Date().toISOString(),
        verified: true,
    };

    const newHistory = [...(dpp.transfer_history || []), transferRecord];

    // Update ownership
    const { error: updateError } = await supabase
        .from('digital_passports')
        .update({
            owner_email: toEmail,
            owner_name: toName || null,
            transfer_history: newHistory,
            updated_at: new Date().toISOString(),
        })
        .eq('uid', uid);

    if (updateError) {
        return { success: false, error: updateError.message };
    }

    return { success: true };
}

// ============================================
// QR Code Generation (Placeholder URL)
// ============================================

export function generateQrCodeUrl(uid: string): string {
    // Generate QR code URL pointing to the public certificate page
    const baseUrl = 'https://kitticker.com/certificate';
    return `https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${encodeURIComponent(`${baseUrl}/${uid}`)}`;
}

// ============================================
// Cross-Validation (Code vs Visual Attributes)
// ============================================

export interface VisualAttributes {
    primary_color?: string;
    kit_type?: 'home' | 'away' | 'third' | 'goalkeeper';
    brand?: string;
}

export interface CrossValidationResult {
    passed: boolean;
    confidence: number;
    mismatches: string[];
}

/**
 * Validate that the visual attributes match what we expect for the code
 * This is the "Data Defense" feature that catches fakes using wrong codes
 */
export async function crossValidateCodeVsVisual(
    code: string,
    visual: VisualAttributes
): Promise<CrossValidationResult> {
    // Get the product code data
    const { data: product, error } = await supabase
        .from('product_codes')
        .select('*')
        .eq('code', code)
        .single();

    if (error || !product) {
        return {
            passed: false,
            confidence: 0,
            mismatches: ['Code not found in database'],
        };
    }

    const mismatches: string[] = [];
    let matchedSignals = 0;
    let totalSignals = 0;

    // Check brand
    if (visual.brand) {
        totalSignals++;
        if (product.brand?.toLowerCase() === visual.brand.toLowerCase()) {
            matchedSignals++;
        } else {
            mismatches.push(`Brand mismatch: expected ${product.brand}, got ${visual.brand}`);
        }
    }

    // Check primary color
    if (visual.primary_color && product.primary_color) {
        totalSignals++;
        if (normalizeColor(product.primary_color) === normalizeColor(visual.primary_color)) {
            matchedSignals++;
        } else {
            mismatches.push(`Color mismatch: expected ${product.primary_color}, got ${visual.primary_color}`);
        }
    }

    // Check kit type
    if (visual.kit_type && product.kit_type) {
        totalSignals++;
        const expectedType = product.kit_type.toLowerCase();
        const actualType = visual.kit_type.toLowerCase();
        if (expectedType.includes(actualType) || actualType.includes(expectedType)) {
            matchedSignals++;
        } else {
            mismatches.push(`Kit type mismatch: expected ${product.kit_type}, got ${visual.kit_type}`);
        }
    }

    const confidence = totalSignals > 0 ? (matchedSignals / totalSignals) * 100 : 50;

    return {
        passed: mismatches.length === 0,
        confidence,
        mismatches,
    };
}

// ============================================
// Helpers
// ============================================

function normalizeColor(color: string): string {
    const colorMap: Record<string, string> = {
        'red': 'red',
        'scarlet': 'red',
        'crimson': 'red',
        'blue': 'blue',
        'navy': 'blue',
        'royal': 'blue',
        'white': 'white',
        'black': 'black',
        'yellow': 'yellow',
        'gold': 'yellow',
        'amber': 'yellow',
        'green': 'green',
    };

    const normalized = color.toLowerCase().trim();
    return colorMap[normalized] || normalized;
}
