/**
 * KitTicker Multi-Signal Authentication Engine (MSAE)
 * 
 * This module implements a weighted confidence scoring system that combines
 * multiple verification signals to produce an explainable authenticity verdict.
 * 
 * Key Features:
 * - Bayesian-inspired multi-signal scoring
 * - Blacklist detection for known fake codes
 * - Brand-specific format validation
 * - Explainable evidence output
 * - Confidence thresholds with actionable verdicts
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js';

// ============================================
// Configuration
// ============================================

const supabaseUrl = 'https://sjltydrpwavzrrmoaivt.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNqbHR5ZHJwd2F2enJybW9haXZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg2NDQwMzEsImV4cCI6MjA4NDIyMDAzMX0.nPdmhcj3GsvQ8xtE4i2CMptWb9kxMy1NKYyI1M7oT9k';

export const supabase: SupabaseClient = createClient(supabaseUrl, supabaseAnonKey);

// ============================================
// Types
// ============================================

export type Brand = 'Nike' | 'Adidas' | 'Puma' | 'Umbro' | 'Unknown';
export type SignalValue = 'pass' | 'fail' | 'warning' | 'unknown';
export type VerdictType =
    | 'highly_likely_authentic'
    | 'probably_authentic'
    | 'uncertain'
    | 'suspicious'
    | 'likely_fake'
    | 'blacklisted';

export interface ProductCode {
    id: string;
    code: string;
    brand: string;
    team: string | null;
    season: string | null;
    kit_type: string | null;
    variant: string | null;
    verified: boolean;
    verification_source: string;
    lookup_count: number;
    created_at: string;
}

export interface BlacklistCode {
    id: string;
    code: string;
    brand: string;
    reason: string;
    legitimate_use: string | null;
    severity: 'high' | 'medium' | 'low';
    reported_count: number;
}

export interface AuthenticationSignal {
    id: string;
    category: string;
    weight: number;
    confidence: number;
    value: SignalValue;
    evidence: string;
    details?: Record<string, unknown>;
}

export interface VerificationResult {
    code: string;
    normalizedCode: string;
    verdict: VerdictType;
    confidenceScore: number;
    signals: AuthenticationSignal[];
    matchedProduct: ProductCode | null;
    blacklistMatch: BlacklistCode | null;
    recommendation: string;
    timestamp: string;
}

// ============================================
// Signal Weights (sum = 100)
// ============================================

export const SIGNAL_WEIGHTS = {
    // Core signals (reduced to make room for new signals)
    database_match: 25,      // Code found in verified database
    blacklist_check: 20,     // Not on known fake codes list
    format_validation: 15,   // Matches brand's code format
    brand_consistency: 8,    // Brand filter matches result
    era_plausibility: 5,     // Year/season makes sense
    // NEW: DB-driven cross-validation signals
    sponsor_era: 8,          // Sponsor matches team's era
    technology_tier: 7,      // Technology matches brand era (ClimaCool vs AEROREADY)
    label_position: 4,       // Label position matches era (hip_tag vs neck_tag)
    color_suffix: 5,         // Nike color suffix matches primary color (if applicable)
    manufacturing_origin: 3, // Country of manufacture matches era
} as const;

// ============================================
// Confidence Thresholds
// ============================================

const THRESHOLDS = {
    highly_likely_authentic: 90,
    probably_authentic: 70,
    uncertain: 50,
    suspicious: 30,
    likely_fake: 0,
} as const;

// ============================================
// Brand-Specific Code Patterns
// ============================================

export const CODE_PATTERNS: Record<Brand, RegExp[]> = {
    Nike: [
        /^[A-Z]{2}\d{4}-\d{3}$/,  // Modern: CZ3984-100 (strict 2 letters + 4 digits + 3 digits)
        /^\d{6}-\d{3}$/,          // Legacy: 638920-013 (strict 6 digits + 3 digits)
        /^\d{6}$/,                // Early (2002-2006): 118834 (strict 6 digits only)
    ],
    Adidas: [
        /^[A-Z]{2}\d{4}$/,        // Modern: IS7462, AC1414 (strict 2 letters + 4 digits)
        /^[A-Z]\d{5}$/,           // Legacy: M36158 (strict 1 letter + 5 digits)
        /^[A-Z]{2}\d{5}$/,        // IT9785 format (2 letters + 5 digits)
    ],
    Puma: [
        /^\d{6}-\d{2}$/,          // 736251-01 (strict 6 digits + 2 digits)
    ],
    Umbro: [
        /^\d{5}-U$/i,             // 96281-U (strict 5 digits + U)
        /^\d{5,6}$/,              // Pure numeric 5-6 digits
    ],
    Unknown: [],
};

// ============================================
// Core Functions
// ============================================

/**
 * Detect brand from code format
 */
export function detectBrandFromCode(code: string): Brand {
    const normalizedCode = code.trim().toUpperCase();

    for (const [brand, patterns] of Object.entries(CODE_PATTERNS)) {
        if (patterns.some(p => p.test(normalizedCode))) {
            return brand as Brand;
        }
    }

    return 'Unknown';
}

/**
 * Validate code format against brand patterns
 */
export function validateCodeFormat(code: string, brand: Brand): AuthenticationSignal {
    const normalizedCode = code.trim().toUpperCase();
    const patterns = CODE_PATTERNS[brand] || [];

    if (patterns.length === 0) {
        return {
            id: 'format_validation',
            category: 'Code Format',
            weight: SIGNAL_WEIGHTS.format_validation,
            confidence: 0.5,
            value: 'unknown',
            evidence: `Unknown brand "${brand}" - cannot validate format`,
        };
    }

    const isValid = patterns.some(p => p.test(normalizedCode));

    return {
        id: 'format_validation',
        category: 'Code Format',
        weight: SIGNAL_WEIGHTS.format_validation,
        confidence: isValid ? 0.95 : 0.3,
        value: isValid ? 'pass' : 'warning',
        evidence: isValid
            ? `Code "${normalizedCode}" matches ${brand} format pattern`
            : `Code "${normalizedCode}" does not match expected ${brand} format`,
    };
}

/**
 * Nike Color Suffix Validation (Deep Research Cross-Validation)
 * Color suffix first digit: 6=Red, 0=Black, 1=White, 4=Blue, 3=Navy, 2=Yellow
 */
const NIKE_COLOR_SUFFIX_MAP: Record<number, string[]> = {
    6: ['red', 'maroon', 'crimson', 'diablo_red'],
    0: ['black'],
    1: ['white'],
    4: ['blue', 'royal_blue'],
    3: ['navy', 'navy_blue', 'dark_blue'],
    2: ['yellow', 'gold'],
};

export function validateNikeColorSuffix(
    code: string,
    reportedColor?: string
): AuthenticationSignal | null {
    // Only applies to Nike 6-3-digit format
    if (!/^\d{6}-\d{3}$/.test(code)) {
        return null; // Not applicable
    }

    const colorSuffix = code.split('-')[1];
    const firstDigit = parseInt(colorSuffix[0], 10);
    const expectedColors = NIKE_COLOR_SUFFIX_MAP[firstDigit];

    if (!expectedColors) {
        return {
            id: 'color_suffix_validation',
            category: 'Color Suffix Check',
            weight: 15,
            confidence: 0.7,
            value: 'warning',
            evidence: `Unknown color suffix starting with ${firstDigit}`,
        };
    }

    // If no reported color, just return the expectation
    if (!reportedColor) {
        return {
            id: 'color_suffix_validation',
            category: 'Color Suffix Check',
            weight: 15,
            confidence: 0.8,
            value: 'pass',
            evidence: `Color suffix ${colorSuffix} indicates ${expectedColors.join('/')} kit`,
            details: { expected_colors: expectedColors },
        };
    }

    // Cross-validate with reported color
    const normalizedReportedColor = reportedColor.toLowerCase().replace(/\s/g, '_');
    const colorMatches = expectedColors.some(c => normalizedReportedColor.includes(c));

    if (colorMatches) {
        return {
            id: 'color_suffix_validation',
            category: 'Color Suffix Check',
            weight: 15,
            confidence: 0.95,
            value: 'pass',
            evidence: `Color suffix ${colorSuffix} matches reported ${reportedColor} color`,
        };
    } else {
        return {
            id: 'color_suffix_validation',
            category: 'Color Suffix Check',
            weight: 15,
            confidence: 0.9,
            value: 'fail',
            evidence: `⚠️ MISMATCH: Suffix ${colorSuffix} expects ${expectedColors.join('/')} but reported color is ${reportedColor}. Possible cloned code!`,
        };
    }
}

/**
 * Check code against blacklist
 */
export async function checkBlacklist(code: string): Promise<{
    signal: AuthenticationSignal;
    match: BlacklistCode | null;
}> {
    const normalizedCode = code.trim().toUpperCase();

    const { data, error } = await supabase
        .from('blacklist_codes')
        .select('*')
        .eq('code', normalizedCode)
        .single();

    if (error || !data) {
        return {
            signal: {
                id: 'blacklist_check',
                category: 'Blacklist Check',
                weight: SIGNAL_WEIGHTS.blacklist_check,
                confidence: 0.95,
                value: 'pass',
                evidence: 'Code not found on known fake codes blacklist',
            },
            match: null,
        };
    }

    return {
        signal: {
            id: 'blacklist_check',
            category: 'Blacklist Check',
            weight: SIGNAL_WEIGHTS.blacklist_check,
            confidence: 1.0,
            value: 'fail',
            evidence: `⚠️ BLACKLISTED: ${data.reason}`,
            details: {
                severity: data.severity,
                legitimate_use: data.legitimate_use,
            },
        },
        match: data,
    };
}

// ============================================
// Deep Research Validation Rules Engine (Database-Driven)
// ============================================

/**
 * RULE 1: Manufacturer-Era Consistency Validation (DATABASE-DRIVEN)
 * Queries team_manufacturer_eras table to validate brand matches era
 */
export async function validateManufacturerEraConsistencyDB(
    brand: string,
    season: string,
    teamName: string
): Promise<AuthenticationSignal | null> {
    // Parse season year (e.g., "2007/08" -> 2007)
    const seasonMatch = season.match(/(\d{4})/);
    if (!seasonMatch) return null;
    const seasonYear = parseInt(seasonMatch[1], 10);

    // Query database for team's manufacturer eras
    const { data: eras, error } = await supabase
        .from('team_manufacturer_eras')
        .select(`
            start_year,
            end_year,
            manufacturers!inner(name)
        `)
        .eq('teams.name', teamName);

    // Fallback to hardcoded for Manchester United if DB query fails
    if (error || !eras || eras.length === 0) {
        // Fallback hardcoded eras (Manchester United)
        const MANCHESTER_UNITED_ERAS = [
            { manufacturer: 'Umbro', startYear: 1975, endYear: 2002 },
            { manufacturer: 'Nike', startYear: 2002, endYear: 2015 },
            { manufacturer: 'Adidas', startYear: 2015, endYear: 2030 },
        ];

        if (teamName.toLowerCase() !== 'manchester united') {
            return null;
        }

        const expectedEra = MANCHESTER_UNITED_ERAS.find(
            era => seasonYear >= era.startYear && seasonYear < era.endYear
        );

        if (!expectedEra) return null;

        const brandsMatch = brand.toLowerCase() === expectedEra.manufacturer.toLowerCase();

        if (!brandsMatch) {
            return {
                id: 'manufacturer_era_consistency',
                category: 'Historical Validation',
                weight: 25,
                confidence: 1.0,
                value: 'fail',
                evidence: `⛔ HISTORICAL IMPOSSIBILITY: ${teamName} was sponsored by ${expectedEra.manufacturer} in ${seasonYear}, not ${brand}.`,
            };
        }

        return {
            id: 'manufacturer_era_consistency',
            category: 'Historical Validation',
            weight: 25,
            confidence: 0.95,
            value: 'pass',
            evidence: `${brand} was the official manufacturer for ${teamName} in ${seasonYear}`,
        };
    }

    // Find expected manufacturer for this year from DB
    const expectedEra = eras.find(
        (era: { start_year: number; end_year: number | null }) =>
            seasonYear >= era.start_year &&
            (era.end_year === null || seasonYear < era.end_year)
    );

    if (!expectedEra) {
        return {
            id: 'manufacturer_era_consistency',
            category: 'Historical Validation',
            weight: 25,
            confidence: 0.7,
            value: 'warning',
            evidence: `No manufacturer era data found for ${teamName} in ${seasonYear}`,
        };
    }

    const expectedManufacturer = (expectedEra as unknown as { manufacturers: { name: string } }).manufacturers.name;
    const brandsMatch = brand.toLowerCase() === expectedManufacturer.toLowerCase();

    if (!brandsMatch) {
        return {
            id: 'manufacturer_era_consistency',
            category: 'Historical Validation',
            weight: 25,
            confidence: 1.0,
            value: 'fail',
            evidence: `⛔ HISTORICAL IMPOSSIBILITY: ${teamName} was sponsored by ${expectedManufacturer} in ${seasonYear}, not ${brand}. This is a definitive fake.`,
        };
    }

    return {
        id: 'manufacturer_era_consistency',
        category: 'Historical Validation',
        weight: 25,
        confidence: 0.95,
        value: 'pass',
        evidence: `${brand} was the official manufacturer for ${teamName} in ${seasonYear} (verified from database)`,
    };
}

/**
 * RULE 4: Visual Cross-Reference Validation
 * Detects when code color doesn't match reported visual color (label swap/clone)
 */
export function validateVisualCrossReference(
    expectedColor: string | undefined,
    reportedColor: string | undefined
): AuthenticationSignal | null {
    if (!expectedColor || !reportedColor) {
        return null;
    }

    const normalizedExpected = expectedColor.toLowerCase().replace(/[_\s-]/g, '');
    const normalizedReported = reportedColor.toLowerCase().replace(/[_\s-]/g, '');

    // Check if colors match or are similar
    const colorMatches = normalizedReported.includes(normalizedExpected) ||
        normalizedExpected.includes(normalizedReported) ||
        (normalizedExpected.includes('red') && normalizedReported.includes('red')) ||
        (normalizedExpected.includes('blue') && normalizedReported.includes('blue')) ||
        (normalizedExpected.includes('white') && normalizedReported.includes('white')) ||
        (normalizedExpected.includes('black') && normalizedReported.includes('black'));

    if (!colorMatches) {
        return {
            id: 'visual_cross_reference',
            category: 'Visual Cross-Reference',
            weight: 20,
            confidence: 0.9,
            value: 'fail',
            evidence: `⚠️ COLOR MISMATCH: Code indicates ${expectedColor} kit but reported color is ${reportedColor}. Possible label swap or cloned code!`,
        };
    }

    return {
        id: 'visual_cross_reference',
        category: 'Visual Cross-Reference',
        weight: 20,
        confidence: 0.95,
        value: 'pass',
        evidence: `Visual color (${reportedColor}) matches expected color (${expectedColor})`,
    };
}

// ============================================
// NEW: DB-Driven Cross-Validation Functions
// ============================================

/**
 * RULE 2: Sponsor Era Validation (DATABASE-DRIVEN)
 * Validates that the sponsor on the shirt matches the team's sponsor for that season.
 * Example: Chevrolet on a 2007 Man Utd shirt = FAKE (should be AIG)
 */
export async function validateSponsorEra(
    team: string,
    season: string,
    productSponsor?: string
): Promise<AuthenticationSignal | null> {
    if (!team || !season || !productSponsor) return null;

    // Parse season year (e.g., "2007/08" -> 2007)
    const seasonMatch = season.match(/(\d{4})/);
    if (!seasonMatch) return null;
    const seasonYear = parseInt(seasonMatch[1], 10);

    // Query team_sponsor_eras table
    const { data: sponsorEras, error } = await supabase
        .from('team_sponsor_eras')
        .select(`
            sponsor_name,
            start_year,
            end_year,
            teams!inner(name)
        `)
        .eq('teams.name', team);

    if (error || !sponsorEras || sponsorEras.length === 0) {
        // Fallback hardcoded for Manchester United
        const MAN_UTD_SPONSORS: Record<string, [number, number]> = {
            'Sharp': [1982, 2000],
            'Vodafone': [2000, 2006],
            'AIG': [2006, 2010],
            'Aon': [2010, 2014],
            'AON': [2010, 2014],
            'Chevrolet': [2014, 2021],
            'TeamViewer': [2021, 2024],
            'Snapdragon': [2024, 2030],
        };

        if (team.toLowerCase() !== 'manchester united') return null;

        const expectedSponsor = Object.entries(MAN_UTD_SPONSORS).find(
            ([, [start, end]]) => seasonYear >= start && seasonYear < end
        );

        if (!expectedSponsor) return null;

        const sponsorMatches = productSponsor.toLowerCase().includes(expectedSponsor[0].toLowerCase()) ||
            expectedSponsor[0].toLowerCase().includes(productSponsor.toLowerCase());

        if (!sponsorMatches) {
            return {
                id: 'sponsor_era',
                category: 'Sponsor Era Check',
                weight: SIGNAL_WEIGHTS.sponsor_era,
                confidence: 1.0,
                value: 'fail',
                evidence: `⛔ SPONSOR MISMATCH: ${team} had ${expectedSponsor[0]} in ${seasonYear}, not ${productSponsor}. Possible fake!`,
            };
        }

        return {
            id: 'sponsor_era',
            category: 'Sponsor Era Check',
            weight: SIGNAL_WEIGHTS.sponsor_era,
            confidence: 0.95,
            value: 'pass',
            evidence: `Sponsor ${productSponsor} matches ${team}'s sponsor for ${seasonYear}`,
        };
    }

    // Find expected sponsor for this season from DB
    const expectedEra = sponsorEras.find(
        (era: { start_year: number; end_year: number | null }) =>
            seasonYear >= era.start_year &&
            (era.end_year === null || seasonYear < era.end_year)
    );

    if (!expectedEra) return null;

    const expectedSponsor = (expectedEra as { sponsor_name: string }).sponsor_name;
    const sponsorMatches = productSponsor.toLowerCase().includes(expectedSponsor.toLowerCase()) ||
        expectedSponsor.toLowerCase().includes(productSponsor.toLowerCase());

    if (!sponsorMatches) {
        return {
            id: 'sponsor_era',
            category: 'Sponsor Era Check',
            weight: SIGNAL_WEIGHTS.sponsor_era,
            confidence: 1.0,
            value: 'fail',
            evidence: `⛔ SPONSOR MISMATCH: ${team} had ${expectedSponsor} in ${seasonYear}, not ${productSponsor}. Definitive fake indicator!`,
        };
    }

    return {
        id: 'sponsor_era',
        category: 'Sponsor Era Check',
        weight: SIGNAL_WEIGHTS.sponsor_era,
        confidence: 0.95,
        value: 'pass',
        evidence: `Sponsor ${productSponsor} verified for ${team} in ${seasonYear} (from database)`,
    };
}

/**
 * RULE 3: Technology Tier Validation
 * Validates that the technology matches the brand's era.
 * Adidas: ClimaCool (2015-2019) → AEROREADY (2020+), HEAT.RDY = authentic only
 * Nike: Dri-FIT, Cool Motion (early)
 */
export async function validateTechnologyTier(
    brand: string,
    season: string,
    productTechnology?: string,
    productTier?: string
): Promise<AuthenticationSignal | null> {
    if (!brand || !season || !productTechnology) return null;

    const seasonMatch = season.match(/(\d{4})/);
    if (!seasonMatch) return null;
    const seasonYear = parseInt(seasonMatch[1], 10);

    // Adidas technology eras
    if (brand.toLowerCase() === 'adidas') {
        const adidasTechEras: Record<string, [number, number]> = {
            'ClimaCool': [2015, 2020],
            'Climalite': [2015, 2020],
            'AEROREADY': [2020, 2030],
            'HEAT.RDY': [2020, 2030], // Authentic only
        };

        // Check if technology exists and matches era
        const expectedTech = Object.entries(adidasTechEras).find(
            ([, [start, end]]) => seasonYear >= start && seasonYear < end
        );

        if (!expectedTech) return null;

        // HEAT.RDY validation - should only be on authentic tier
        if (productTechnology === 'HEAT.RDY' && productTier !== 'authentic') {
            return {
                id: 'technology_tier',
                category: 'Technology Tier Check',
                weight: SIGNAL_WEIGHTS.technology_tier,
                confidence: 0.9,
                value: 'warning',
                evidence: `⚠️ HEAT.RDY technology is only used on Authentic tier shirts, not ${productTier || 'replica'}`,
            };
        }

        // Check technology matches era
        const techInRange = adidasTechEras[productTechnology];
        if (techInRange && seasonYear >= techInRange[0] && seasonYear < techInRange[1]) {
            return {
                id: 'technology_tier',
                category: 'Technology Tier Check',
                weight: SIGNAL_WEIGHTS.technology_tier,
                confidence: 0.95,
                value: 'pass',
                evidence: `${productTechnology} technology matches Adidas ${seasonYear} era`,
            };
        }

        // Technology doesn't match era
        if (productTechnology === 'ClimaCool' && seasonYear >= 2020) {
            return {
                id: 'technology_tier',
                category: 'Technology Tier Check',
                weight: SIGNAL_WEIGHTS.technology_tier,
                confidence: 0.85,
                value: 'fail',
                evidence: `⚠️ TECH MISMATCH: ClimaCool was replaced by AEROREADY in 2020. A ${seasonYear} kit shouldn't have ClimaCool.`,
            };
        }

        if (productTechnology === 'AEROREADY' && seasonYear < 2020) {
            return {
                id: 'technology_tier',
                category: 'Technology Tier Check',
                weight: SIGNAL_WEIGHTS.technology_tier,
                confidence: 0.85,
                value: 'fail',
                evidence: `⚠️ TECH MISMATCH: AEROREADY wasn't introduced until 2020. A ${seasonYear} kit shouldn't have AEROREADY.`,
            };
        }
    }

    // Nike technology (Dri-FIT throughout, Cool Motion early)
    if (brand.toLowerCase() === 'nike') {
        const nikeTechEras: Record<string, [number, number]> = {
            'Cool Motion': [2002, 2006],
            'Dri-FIT': [2006, 2030],
        };

        if (productTechnology === 'Cool Motion' && seasonYear >= 2006) {
            return {
                id: 'technology_tier',
                category: 'Technology Tier Check',
                weight: SIGNAL_WEIGHTS.technology_tier,
                confidence: 0.85,
                value: 'warning',
                evidence: `⚠️ Cool Motion was used by Nike from 2002-2006. A ${seasonYear} kit would typically have Dri-FIT.`,
            };
        }

        return {
            id: 'technology_tier',
            category: 'Technology Tier Check',
            weight: SIGNAL_WEIGHTS.technology_tier,
            confidence: 0.9,
            value: 'pass',
            evidence: `${productTechnology} technology consistent with Nike standards`,
        };
    }

    return null;
}

/**
 * RULE 4: Label Position Era Validation
 * Adidas shifted label position from hip to neck in 2020
 */
export function validateLabelPositionEra(
    brand: string,
    season: string,
    labelPositionEra?: string
): AuthenticationSignal | null {
    if (!brand || !season || !labelPositionEra) return null;

    const seasonMatch = season.match(/(\d{4})/);
    if (!seasonMatch) return null;
    const seasonYear = parseInt(seasonMatch[1], 10);

    // Only Adidas has documented label position shift
    if (brand.toLowerCase() !== 'adidas') return null;

    const expectedPosition = seasonYear >= 2020 ? 'neck_tag' : 'hip_tag';
    const positionMatches = labelPositionEra.toLowerCase() === expectedPosition;

    if (!positionMatches) {
        return {
            id: 'label_position',
            category: 'Label Position Era',
            weight: SIGNAL_WEIGHTS.label_position,
            confidence: 0.8,
            value: 'warning',
            evidence: `⚠️ Label position mismatch: ${seasonYear} Adidas kits typically have ${expectedPosition}, not ${labelPositionEra}`,
        };
    }

    return {
        id: 'label_position',
        category: 'Label Position Era',
        weight: SIGNAL_WEIGHTS.label_position,
        confidence: 0.9,
        value: 'pass',
        evidence: `Label position ${labelPositionEra} matches Adidas ${seasonYear} manufacturing standard`,
    };
}

/**
 * RULE 5: Manufacturing Origin Era Validation
 * Validates country of manufacture against expected era
 * Example: Nike 2015 = Thailand, Nike 2022 = Indonesia/Vietnam
 */
export function validateManufacturingOrigin(
    brand: string,
    season: string,
    countryOfManufacture?: string
): AuthenticationSignal | null {
    if (!brand || !season || !countryOfManufacture) return null;

    const seasonMatch = season.match(/(\d{4})/);
    if (!seasonMatch) return null;
    const seasonYear = parseInt(seasonMatch[1], 10);

    const normalizedCountry = countryOfManufacture.toLowerCase().trim();

    // Nike manufacturing eras
    if (brand.toLowerCase() === 'nike') {
        const nikeOrigins: { country: string; startYear: number; endYear: number }[] = [
            { country: 'china', startYear: 1990, endYear: 2010 },
            { country: 'thailand', startYear: 2005, endYear: 2015 },
            { country: 'vietnam', startYear: 2012, endYear: 2030 },
            { country: 'indonesia', startYear: 2015, endYear: 2030 },
            { country: 'cambodia', startYear: 2018, endYear: 2030 },
        ];

        const expectedOrigins = nikeOrigins.filter(
            o => seasonYear >= o.startYear && seasonYear < o.endYear
        );

        if (expectedOrigins.length === 0) {
            return {
                id: 'manufacturing_origin',
                category: 'Manufacturing Origin',
                weight: 5,
                confidence: 0.5,
                value: 'unknown',
                evidence: `No manufacturing data for Nike ${seasonYear}`,
            };
        }

        const originMatch = expectedOrigins.some(o => normalizedCountry.includes(o.country));

        if (!originMatch) {
            const expectedList = expectedOrigins.map(o => o.country).join(', ');
            return {
                id: 'manufacturing_origin',
                category: 'Manufacturing Origin',
                weight: 5,
                confidence: 0.75,
                value: 'warning',
                evidence: `⚠️ Nike ${seasonYear} kits were typically made in ${expectedList}, not ${countryOfManufacture}`,
            };
        }

        return {
            id: 'manufacturing_origin',
            category: 'Manufacturing Origin',
            weight: 5,
            confidence: 0.9,
            value: 'pass',
            evidence: `${countryOfManufacture} is a valid manufacturing origin for Nike ${seasonYear}`,
        };
    }

    // Adidas manufacturing eras
    if (brand.toLowerCase() === 'adidas') {
        const adidasOrigins: { country: string; startYear: number; endYear: number }[] = [
            { country: 'china', startYear: 1990, endYear: 2012 },
            { country: 'thailand', startYear: 2008, endYear: 2020 },
            { country: 'indonesia', startYear: 2015, endYear: 2030 },
            { country: 'vietnam', startYear: 2018, endYear: 2030 },
            { country: 'cambodia', startYear: 2020, endYear: 2030 },
        ];

        const expectedOrigins = adidasOrigins.filter(
            o => seasonYear >= o.startYear && seasonYear < o.endYear
        );

        if (expectedOrigins.length === 0) {
            return {
                id: 'manufacturing_origin',
                category: 'Manufacturing Origin',
                weight: 5,
                confidence: 0.5,
                value: 'unknown',
                evidence: `No manufacturing data for Adidas ${seasonYear}`,
            };
        }

        const originMatch = expectedOrigins.some(o => normalizedCountry.includes(o.country));

        if (!originMatch) {
            const expectedList = expectedOrigins.map(o => o.country).join(', ');
            return {
                id: 'manufacturing_origin',
                category: 'Manufacturing Origin',
                weight: 5,
                confidence: 0.75,
                value: 'warning',
                evidence: `⚠️ Adidas ${seasonYear} kits were typically made in ${expectedList}, not ${countryOfManufacture}`,
            };
        }

        return {
            id: 'manufacturing_origin',
            category: 'Manufacturing Origin',
            weight: 5,
            confidence: 0.9,
            value: 'pass',
            evidence: `${countryOfManufacture} is a valid manufacturing origin for Adidas ${seasonYear}`,
        };
    }

    // Puma manufacturing
    if (brand.toLowerCase() === 'puma') {
        // Puma primarily manufactures in Vietnam and Cambodia
        const validPumaOrigins = ['vietnam', 'cambodia', 'china', 'turkey'];
        const originMatch = validPumaOrigins.some(o => normalizedCountry.includes(o));

        return {
            id: 'manufacturing_origin',
            category: 'Manufacturing Origin',
            weight: 5,
            confidence: originMatch ? 0.85 : 0.6,
            value: originMatch ? 'pass' : 'warning',
            evidence: originMatch
                ? `${countryOfManufacture} is a known Puma manufacturing location`
                : `${countryOfManufacture} is an unusual origin for Puma kits`,
        };
    }

    return null;
}

/**
 * Enhanced Color Suffix Validation using DB data
 * Uses expected_suffix_digit from product_codes table
 */
export function validateColorSuffixFromDB(
    code: string,
    expectedSuffixDigit?: number,
    primaryColor?: string
): AuthenticationSignal | null {
    // Only applies to Nike 6-3-digit format
    if (!/^\d{6}-\d{3}$/.test(code)) return null;
    if (expectedSuffixDigit === undefined || expectedSuffixDigit === null) return null;

    const colorSuffix = code.split('-')[1];
    const actualFirstDigit = parseInt(colorSuffix[0], 10);

    if (actualFirstDigit !== expectedSuffixDigit) {
        return {
            id: 'color_suffix',
            category: 'Color Suffix Validation',
            weight: SIGNAL_WEIGHTS.color_suffix,
            confidence: 0.95,
            value: 'fail',
            evidence: `⚠️ COLOR CODE MISMATCH: Suffix ${colorSuffix} starts with ${actualFirstDigit} but database expects ${expectedSuffixDigit} for ${primaryColor || 'this color'}. Possible code manipulation!`,
        };
    }

    return {
        id: 'color_suffix',
        category: 'Color Suffix Validation',
        weight: SIGNAL_WEIGHTS.color_suffix,
        confidence: 0.95,
        value: 'pass',
        evidence: `Color suffix ${colorSuffix} verified: digit ${actualFirstDigit} matches expected for ${primaryColor || 'this kit color'}`,
    };
}

/**
 * Look up code in verified database
 */
export async function lookupProductCode(
    code: string,
    brandFilter?: string
): Promise<{
    signal: AuthenticationSignal;
    match: ProductCode | null;
}> {
    const normalizedCode = code.trim().toUpperCase();

    let query = supabase
        .from('product_codes')
        .select('*')
        .eq('code', normalizedCode);

    if (brandFilter && brandFilter !== 'all') {
        query = query.eq('brand', brandFilter);
    }

    const { data, error } = await query.single();

    if (error || !data) {
        return {
            signal: {
                id: 'database_match',
                category: 'Database Match',
                weight: SIGNAL_WEIGHTS.database_match,
                confidence: 0.6,  // Lower confidence because DB may be incomplete
                value: 'unknown',
                evidence: 'Code not found in our verified database',
            },
            match: null,
        };
    }

    // Increment lookup count (fire and forget)
    supabase
        .from('product_codes')
        .update({ lookup_count: (data.lookup_count || 0) + 1 })
        .eq('id', data.id)
        .then(() => { });

    return {
        signal: {
            id: 'database_match',
            category: 'Database Match',
            weight: SIGNAL_WEIGHTS.database_match,
            confidence: data.verified ? 1.0 : 0.7,
            value: 'pass',
            evidence: `✓ Matches ${data.brand} ${data.team} ${data.season} ${data.kit_type}`,
            details: {
                team: data.team,
                season: data.season,
                kit_type: data.kit_type,
                verified: data.verified,
                source: data.verification_source,
            },
        },
        match: data,
    };
}

/**
 * Check brand consistency
 */
export function checkBrandConsistency(
    detectedBrand: Brand,
    selectedBrand: string | undefined,
    matchedBrand: string | null
): AuthenticationSignal {
    if (!selectedBrand || selectedBrand === 'all') {
        return {
            id: 'brand_consistency',
            category: 'Brand Consistency',
            weight: SIGNAL_WEIGHTS.brand_consistency,
            confidence: 0.8,
            value: 'pass',
            evidence: 'No brand filter applied',
        };
    }

    const brandsMatch = matchedBrand
        ? matchedBrand.toLowerCase() === selectedBrand.toLowerCase()
        : detectedBrand.toLowerCase() === selectedBrand.toLowerCase();

    return {
        id: 'brand_consistency',
        category: 'Brand Consistency',
        weight: SIGNAL_WEIGHTS.brand_consistency,
        confidence: brandsMatch ? 0.95 : 0.4,
        value: brandsMatch ? 'pass' : 'warning',
        evidence: brandsMatch
            ? `Brand matches selected filter (${selectedBrand})`
            : `Brand mismatch: expected ${selectedBrand}, detected ${detectedBrand}`,
    };
}

/**
 * Calculate weighted confidence score
 */
export function calculateConfidenceScore(signals: AuthenticationSignal[]): number {
    let totalWeight = 0;
    let weightedSum = 0;

    for (const signal of signals) {
        if (signal.value === 'unknown') continue;

        const signalScore = signal.value === 'pass' ? 1 : signal.value === 'warning' ? 0.5 : 0;
        const effectiveWeight = signal.weight * signal.confidence;

        weightedSum += signalScore * effectiveWeight;
        totalWeight += effectiveWeight;
    }

    if (totalWeight === 0) return 50; // Neutral score

    return Math.round((weightedSum / totalWeight) * 100);
}

/**
 * Determine verdict from confidence score
 */
export function determineVerdict(
    score: number,
    isBlacklisted: boolean
): VerdictType {
    if (isBlacklisted) return 'blacklisted';
    if (score >= THRESHOLDS.highly_likely_authentic) return 'highly_likely_authentic';
    if (score >= THRESHOLDS.probably_authentic) return 'probably_authentic';
    if (score >= THRESHOLDS.uncertain) return 'uncertain';
    if (score >= THRESHOLDS.suspicious) return 'suspicious';
    return 'likely_fake';
}

/**
 * Generate recommendation based on verdict
 */
export function generateRecommendation(verdict: VerdictType): string {
    const recommendations: Record<VerdictType, string> = {
        highly_likely_authentic: 'This code strongly indicates an authentic product. Proceed with confidence.',
        probably_authentic: 'This code appears legitimate. Consider additional visual checks for high-value items.',
        uncertain: 'We cannot definitively verify this code. Recommend additional authentication methods.',
        suspicious: 'Several warning signs detected. Exercise caution and consider expert verification.',
        likely_fake: 'Multiple indicators suggest this may be counterfeit. Strongly recommend avoiding purchase.',
        blacklisted: 'This code is known to be used on counterfeit products. Do not purchase.',
    };

    return recommendations[verdict];
}

// ============================================
// Main Verification Function
// ============================================

/**
 * Perform full multi-signal verification on a product code
 * Enhanced with DB-driven cross-validation signals
 */
export async function verifyProductCode(
    code: string,
    options: {
        brandFilter?: string;
    } = {}
): Promise<VerificationResult> {
    const normalizedCode = code.trim().toUpperCase();
    const signals: AuthenticationSignal[] = [];

    // 1. Detect brand from code format
    const detectedBrand = detectBrandFromCode(normalizedCode);

    // 2. Check blacklist first (critical check)
    const blacklistResult = await checkBlacklist(normalizedCode);
    signals.push(blacklistResult.signal);

    // 3. Look up in verified database
    const databaseResult = await lookupProductCode(normalizedCode, options.brandFilter);
    signals.push(databaseResult.signal);

    // 4. Validate code format
    const effectiveBrand = databaseResult.match?.brand as Brand || detectedBrand;
    const formatSignal = validateCodeFormat(normalizedCode, effectiveBrand);
    signals.push(formatSignal);

    // 5. Check brand consistency
    const brandSignal = checkBrandConsistency(
        detectedBrand,
        options.brandFilter,
        databaseResult.match?.brand || null
    );
    signals.push(brandSignal);

    // ============================================
    // 6. NEW: DB-Driven Cross-Validation Signals
    // These only run if we have a database match with rich metadata
    // ============================================
    const product = databaseResult.match as Record<string, unknown> | null;

    if (product) {
        const team = product.team as string | undefined;
        const season = product.season as string | undefined;
        const brand = product.brand as string | undefined;
        const sponsor = product.sponsor as string | undefined;
        const technology = product.technology as string | undefined;
        const tier = product.tier as string | undefined;
        const labelPositionEra = product.label_position_era as string | undefined;
        const expectedSuffixDigit = product.expected_suffix_digit as number | undefined;
        const primaryColor = product.primary_color as string | undefined;

        // 6a. Sponsor Era Validation
        if (team && season && sponsor) {
            const sponsorSignal = await validateSponsorEra(team, season, sponsor);
            if (sponsorSignal) signals.push(sponsorSignal);
        }

        // 6b. Technology Tier Validation
        if (brand && season && technology) {
            const techSignal = await validateTechnologyTier(brand, season, technology, tier);
            if (techSignal) signals.push(techSignal);
        }

        // 6c. Label Position Era Validation (Adidas only)
        if (brand && season && labelPositionEra) {
            const labelSignal = validateLabelPositionEra(brand, season, labelPositionEra);
            if (labelSignal) signals.push(labelSignal);
        }

        // 6d. Color Suffix Validation (Nike 6-3-digit only)
        if (expectedSuffixDigit !== undefined) {
            const colorSuffixSignal = validateColorSuffixFromDB(normalizedCode, expectedSuffixDigit, primaryColor);
            if (colorSuffixSignal) signals.push(colorSuffixSignal);
        }

        // 6e. Manufacturer Era Validation (existing function, now integrated)
        if (brand && season && team) {
            const mfgSignal = await validateManufacturerEraConsistencyDB(brand, season, team);
            if (mfgSignal) signals.push(mfgSignal);
        }
    }

    // 7. Calculate final score
    const confidenceScore = calculateConfidenceScore(signals);
    const isBlacklisted = blacklistResult.match !== null;
    const verdict = determineVerdict(confidenceScore, isBlacklisted);
    const recommendation = generateRecommendation(verdict);

    // 8. Log verification (async, don't await)
    logVerification(normalizedCode, options.brandFilter, verdict, confidenceScore, signals);

    return {
        code,
        normalizedCode,
        verdict,
        confidenceScore: isBlacklisted ? 0 : confidenceScore,
        signals,
        matchedProduct: databaseResult.match,
        blacklistMatch: blacklistResult.match,
        recommendation,
        timestamp: new Date().toISOString(),
    };
}

/**
 * Log verification for analytics (fire and forget)
 */
async function logVerification(
    code: string,
    brandFilter: string | undefined,
    resultType: VerdictType,
    confidenceScore: number,
    signals: AuthenticationSignal[]
): Promise<void> {
    try {
        await supabase.from('verification_logs').insert({
            code_checked: code,
            brand_filter: brandFilter || null,
            result_type: resultType,
            confidence_score: confidenceScore,
            signals_used: signals.map(s => ({ id: s.id, value: s.value })),
        });
    } catch (e) {
        // Silently fail - logging shouldn't break verification
        console.warn('Failed to log verification:', e);
    }
}

// ============================================
// UI Helper Functions
// ============================================

/**
 * Get color scheme for verdict
 */
export function getVerdictColors(verdict: VerdictType): {
    bg: string;
    border: string;
    text: string;
    icon: string;
} {
    type VerdictColorStyle = { bg: string; border: string; text: string; icon: string };
    const colors: Record<VerdictType, VerdictColorStyle> = {
        highly_likely_authentic: {
            bg: 'bg-emerald-500/10',
            border: 'border-emerald-500/30',
            text: 'text-emerald-400',
            icon: '✓',
        },
        probably_authentic: {
            bg: 'bg-green-500/10',
            border: 'border-green-500/30',
            text: 'text-green-400',
            icon: '✓',
        },
        uncertain: {
            bg: 'bg-yellow-500/10',
            border: 'border-yellow-500/30',
            text: 'text-yellow-400',
            icon: '?',
        },
        suspicious: {
            bg: 'bg-orange-500/10',
            border: 'border-orange-500/30',
            text: 'text-orange-400',
            icon: '⚠',
        },
        likely_fake: {
            bg: 'bg-red-500/10',
            border: 'border-red-500/30',
            text: 'text-red-400',
            icon: '✗',
        },
        blacklisted: {
            bg: 'bg-red-600/20',
            border: 'border-red-600/50',
            text: 'text-red-500',
            icon: '⛔',
        },
    };

    return colors[verdict];
}

/**
 * Get human-readable verdict label
 */
export function getVerdictLabel(verdict: VerdictType): string {
    const labels: Record<VerdictType, string> = {
        highly_likely_authentic: 'Highly Likely Authentic',
        probably_authentic: 'Probably Authentic',
        uncertain: 'Uncertain',
        suspicious: 'Suspicious',
        likely_fake: 'Likely Fake',
        blacklisted: 'Known Counterfeit',
    };

    return labels[verdict];
}

/**
 * Format confidence score for display
 */
export function formatConfidenceScore(score: number): string {
    return `${score}%`;
}

// ============================================
// Visual Cross-Validation
// ============================================

export interface VisualData {
    dominantColor: string | null;
    sponsorHint: string | null;
    technologyHint: string | null;
    colorConfidence: number;
}

export interface VisualCrossCheckResult {
    colorMatch: 'pass' | 'fail' | 'unknown';
    colorEvidence: string;
    sponsorMatch: 'pass' | 'fail' | 'unknown';
    sponsorEvidence: string;
    technologyMatch: 'pass' | 'fail' | 'unknown';
    technologyEvidence: string;
}

/**
 * Cross-validate visual data against DB product data
 */
function crossValidateVisualData(
    product: ProductCode | null,
    visualData: VisualData
): VisualCrossCheckResult {
    const result: VisualCrossCheckResult = {
        colorMatch: 'unknown',
        colorEvidence: 'No visual color data available',
        sponsorMatch: 'unknown',
        sponsorEvidence: 'No sponsor detected in image',
        technologyMatch: 'unknown',
        technologyEvidence: 'No technology detected in image',
    };

    if (!product) {
        return result;
    }

    // Type assertion for extended product fields
    const extendedProduct = product as ProductCode & {
        primary_color?: string;
        sponsor?: string;
        technology?: string;
    };

    // Color cross-validation
    if (visualData.dominantColor && visualData.colorConfidence > 40) {
        const dbColor = extendedProduct.primary_color?.toLowerCase();
        const imageColor = visualData.dominantColor.toLowerCase();

        if (dbColor) {
            const colorsMatch = dbColor === imageColor ||
                (dbColor.includes(imageColor)) ||
                (imageColor.includes(dbColor));

            result.colorMatch = colorsMatch ? 'pass' : 'fail';
            result.colorEvidence = colorsMatch
                ? `✓ Image color (${imageColor}) matches expected (${dbColor})`
                : `⚠ Image color (${imageColor}) differs from expected (${dbColor})`;
        } else {
            result.colorMatch = 'unknown';
            result.colorEvidence = `Image shows ${imageColor} - no DB reference to compare`;
        }
    }

    // Sponsor cross-validation
    if (visualData.sponsorHint) {
        const dbSponsor = extendedProduct.sponsor?.toLowerCase();
        const imageSponsor = visualData.sponsorHint.toLowerCase();

        if (dbSponsor) {
            const sponsorsMatch = dbSponsor.includes(imageSponsor) || imageSponsor.includes(dbSponsor);

            result.sponsorMatch = sponsorsMatch ? 'pass' : 'fail';
            result.sponsorEvidence = sponsorsMatch
                ? `✓ Detected sponsor (${visualData.sponsorHint}) matches DB`
                : `⚠ Detected sponsor (${visualData.sponsorHint}) differs from expected (${extendedProduct.sponsor})`;
        } else {
            result.sponsorMatch = 'unknown';
            result.sponsorEvidence = `Detected: ${visualData.sponsorHint} - no DB reference`;
        }
    }

    // Technology cross-validation
    if (visualData.technologyHint) {
        const dbTech = extendedProduct.technology?.toLowerCase();
        const imageTech = visualData.technologyHint.toLowerCase();

        if (dbTech) {
            const techsMatch = dbTech.includes(imageTech) || imageTech.includes(dbTech);

            result.technologyMatch = techsMatch ? 'pass' : 'fail';
            result.technologyEvidence = techsMatch
                ? `✓ Detected technology (${visualData.technologyHint}) matches DB`
                : `⚠ Detected technology (${visualData.technologyHint}) differs from expected (${extendedProduct.technology})`;
        } else {
            result.technologyMatch = 'unknown';
            result.technologyEvidence = `Detected: ${visualData.technologyHint} - no DB reference`;
        }
    }

    return result;
}

/**
 * Verify a product code with optional visual cross-validation data
 * This enriches the standard verification with image-based checks
 */
export async function verifyWithVisualData(
    code: string,
    visualData?: VisualData,
    brandFilter?: Brand
): Promise<VerificationResult> {
    // Run standard verification
    const baseResult = await verifyProductCode(code, brandFilter ? { brandFilter } : undefined);

    // If no visual data, return base result
    if (!visualData) {
        return baseResult;
    }

    // Cross-validate visual data
    const visualCheck = crossValidateVisualData(baseResult.matchedProduct, visualData);

    // Update relevant signals with visual cross-validation results
    const updatedSignals = baseResult.signals.map(signal => {
        // Update color_suffix signal with visual color check
        if (signal.id === 'color_suffix' && visualCheck.colorMatch !== 'unknown') {
            return {
                ...signal,
                value: visualCheck.colorMatch,
                evidence: visualCheck.colorEvidence,
                details: { ...signal.details, visualCheck: true }
            };
        }

        // Update sponsor_era signal with visual sponsor check
        if (signal.id === 'sponsor_era' && visualCheck.sponsorMatch !== 'unknown') {
            return {
                ...signal,
                value: visualCheck.sponsorMatch,
                evidence: visualCheck.sponsorEvidence,
                details: { ...signal.details, visualCheck: true }
            };
        }

        // Update technology_tier signal with visual tech check
        if (signal.id === 'technology_tier' && visualCheck.technologyMatch !== 'unknown') {
            return {
                ...signal,
                value: visualCheck.technologyMatch,
                evidence: visualCheck.technologyEvidence,
                details: { ...signal.details, visualCheck: true }
            };
        }

        return signal;
    });

    // Recalculate confidence score with updated signals
    const newConfidence = calculateConfidenceScore(updatedSignals);
    const newVerdict = determineVerdict(newConfidence, baseResult.blacklistMatch !== null);

    return {
        ...baseResult,
        signals: updatedSignals,
        confidenceScore: newConfidence,
        verdict: newVerdict,
        recommendation: baseResult.blacklistMatch
            ? baseResult.recommendation
            : getRecommendation(newVerdict, newConfidence)
    };
}

/**
 * Get recommendation based on verdict (helper for verifyWithVisualData)
 */
function getRecommendation(verdict: VerdictType, confidence: number): string {
    const recommendations: Record<VerdictType, string> = {
        highly_likely_authentic: 'This kit shows strong indicators of authenticity across multiple verification signals.',
        probably_authentic: 'This kit appears authentic based on available verification data.',
        uncertain: 'We cannot conclusively determine authenticity. Manual verification recommended.',
        suspicious: 'This kit shows some concerning indicators. Proceed with caution.',
        likely_fake: 'This kit has multiple indicators suggesting it may not be authentic.',
        blacklisted: 'This code is on our known counterfeit list. Do not purchase.'
    };
    return recommendations[verdict];
}

