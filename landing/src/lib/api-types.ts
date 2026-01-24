// KitTicker API Types & Interfaces
// B2B Data-as-a-Service API

// ============================================
// API Key Management
// ============================================

export type ApiTier = 'free' | 'starter' | 'business' | 'enterprise';

export interface ApiKey {
    id: string;
    key_prefix: string;
    key_hash: string;
    owner_email: string;
    company_name?: string;
    tier: ApiTier;
    rate_limit: number;
    monthly_quota: number;
    usage_this_month: number;
    is_active: boolean;
    metadata: Record<string, unknown>;
    created_at: Date;
    last_used_at?: Date;
}

export const API_TIER_LIMITS: Record<ApiTier, { rateLimit: number; monthlyQuota: number; price: number }> = {
    free: { rateLimit: 100, monthlyQuota: 1000, price: 0 },
    starter: { rateLimit: 500, monthlyQuota: 5000, price: 49 },
    business: { rateLimit: 2000, monthlyQuota: 25000, price: 199 },
    enterprise: { rateLimit: 10000, monthlyQuota: -1, price: -1 }, // Custom
};

// ============================================
// Product Code (Enhanced for B2B)
// ============================================

export interface ProductCode {
    id: string;
    code: string;
    brand: string;
    team?: string;
    season?: string;
    kit_type?: string;
    variant?: string;
    verified: boolean;
    verification_source: 'official' | 'community' | 'ai';

    // B2B Fields
    uid?: string;
    image_url?: string;
    thumbnail_url?: string;

    // Pricing
    estimated_price_min?: number;
    estimated_price_max?: number;
    price_currency: string;
    price_confidence: 'low' | 'medium' | 'high';
    last_price_update?: Date;

    // Visual Attributes (for cross-validation)
    primary_color?: string;
    secondary_color?: string;
    pattern?: string;
    material_composition?: string;

    // Enhanced Tracking (NEW)
    label_type?: 'swing_tag' | 'inner_label' | 'jock_tag' | 'hologram';
    label_position?: string;
    era_start_year?: number;
    era_end_year?: number;
    code_format?: string;
    country_of_manufacture?: string;
    technology?: string;          // 'Dri-FIT', 'AEROREADY', 'ClimaCool'
    sponsor?: string;             // 'Vodafone', 'AIG', 'Chevrolet'
    expected_colors?: string[];   // For cross-validation

    // Statistics
    lookup_count: number;
    api_lookup_count: number;

    created_at: Date;
    updated_at: Date;
}

// ============================================
// Digital Product Passport (DPP)
// ============================================

export interface Transfer {
    from_email: string;
    to_email: string;
    date: Date;
    verified: boolean;
}

export interface VerificationEvidence {
    type: 'code_match' | 'visual_match' | 'expert_review' | 'community_vote';
    confidence: number;
    details: string;
    timestamp: Date;
}

export interface DigitalProductPassport {
    id: string;
    uid: string;  // KT-2026-XXXXXX
    product_code_id: string;

    // Ownership
    owner_email?: string;
    owner_name?: string;
    transfer_history: Transfer[];

    // Verification
    verification_status: 'pending' | 'verified' | 'failed' | 'disputed';
    verification_date?: Date;
    verification_evidence?: VerificationEvidence[];
    verified_by?: 'ai' | 'community' | 'expert';

    // Physical Carriers
    qr_code_url?: string;
    nfc_tag_id?: string;

    notes?: string;
    created_at: Date;
    updated_at: Date;
}

// ============================================
// API Request/Response Types
// ============================================

// GET /api/v1/codes/lookup
export interface CodeLookupRequest {
    code: string;
    include_price?: boolean;
    include_visual?: boolean;
}

export interface CodeLookupResponse {
    success: boolean;
    data?: {
        code: string;
        brand: string;
        team?: string;
        season?: string;
        kit_type?: string;
        variant?: string;
        verified: boolean;

        // Optional based on tier
        image_url?: string;
        thumbnail_url?: string;
        estimated_price?: {
            min: number;
            max: number;
            currency: string;
            confidence: 'low' | 'medium' | 'high';
            last_updated?: Date;
        };
        visual_attributes?: {
            primary_color?: string;
            secondary_color?: string;
            pattern?: string;
        };
    };
    error?: string;
    cached: boolean;
    request_id: string;
}

// POST /api/v1/codes/validate (Batch)
export interface BatchValidateRequest {
    codes: string[];
}

export interface BatchValidateResponse {
    success: boolean;
    results: {
        code: string;
        found: boolean;
        verified: boolean;
        brand?: string;
    }[];
    stats: {
        total: number;
        found: number;
        verified: number;
        blacklisted: number;
    };
    request_id: string;
}

// POST /api/v1/verify (Full Verification)
export interface FullVerifyRequest {
    code: string;
    brand?: string;
    visual_attributes?: {
        primary_color?: string;
        kit_type?: 'home' | 'away' | 'third';
    };
}

export interface FullVerifyResponse {
    success: boolean;
    data?: {
        verdict: 'authentic' | 'likely_authentic' | 'uncertain' | 'suspicious' | 'fake';
        confidence: number;
        evidence: {
            signal: string;
            weight: number;
            passed: boolean;
            details: string;
        }[];
        warnings?: string[];
        product_info?: ProductCode;
    };
    error?: string;
    request_id: string;
}

// POST /api/v1/dpp/generate
export interface DPPGenerateRequest {
    code: string;
    owner_email: string;
    owner_name?: string;
    notes?: string;
}

export interface DPPGenerateResponse {
    success: boolean;
    data?: {
        uid: string;
        qr_code_url: string;
        verification_status: 'pending' | 'verified';
        product_info: ProductCode;
    };
    error?: string;
    request_id: string;
}

// GET /api/v1/dpp/:uid
export interface DPPLookupResponse {
    success: boolean;
    data?: DigitalProductPassport & {
        product: ProductCode;
    };
    error?: string;
    request_id: string;
}

// ============================================
// Error Types
// ============================================

export interface ApiError {
    code: string;
    message: string;
    details?: Record<string, unknown>;
}

export const API_ERRORS = {
    INVALID_API_KEY: { code: 'INVALID_API_KEY', message: 'Invalid or missing API key' },
    RATE_LIMITED: { code: 'RATE_LIMITED', message: 'Rate limit exceeded. Please try again later.' },
    QUOTA_EXCEEDED: { code: 'QUOTA_EXCEEDED', message: 'Monthly quota exceeded. Please upgrade your plan.' },
    CODE_NOT_FOUND: { code: 'CODE_NOT_FOUND', message: 'Product code not found in database' },
    BLACKLISTED: { code: 'BLACKLISTED', message: 'Code is on the known fake list' },
    INVALID_REQUEST: { code: 'INVALID_REQUEST', message: 'Invalid request parameters' },
    INTERNAL_ERROR: { code: 'INTERNAL_ERROR', message: 'Internal server error' },
} as const;
