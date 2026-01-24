/**
 * Image Analyzer Module
 * 
 * Extracts visual data from uploaded images for cross-validation:
 * - Dominant color extraction (Canvas-based)
 * - Sponsor detection (OCR pattern matching)
 * - Technology detection (OCR pattern matching)
 */

// ============================================
// Types
// ============================================

export interface ImageAnalysisResult {
    dominantColor: string | null;       // 'red', 'white', 'blue', etc.
    dominantColorRgb: [number, number, number] | null;
    detectedTexts: string[];            // All OCR text fragments
    sponsorHint: string | null;         // Detected sponsor name
    technologyHint: string | null;      // Detected technology (AEROREADY, etc.)
    colorConfidence: number;            // 0-100
    analysisComplete: boolean;
}

// ============================================
// Known Patterns
// ============================================

const KNOWN_SPONSORS = [
    // Premier League
    'chevrolet', 'aig', 'vodafone', 'sharp', 'aon', 'teamviewer', 'snapdragon',
    'fly emirates', 'emirates', 'etihad', 'standard chartered', 'rakuten',
    'three', '3', 'yokohama', 'samsung', 'o2', 'dreamcast', 'jvc',
    // Serie A
    'pirelli', 'lete', 'bwin',
    // La Liga
    'beko', 'rakuten', 'spotify',
    // General
    'bet365', 'betway', 'w88', 'mansion'
];

const KNOWN_TECHNOLOGIES = [
    // Adidas
    'aeroready', 'climacool', 'climalite', 'heat.rdy', 'cold.rdy', 'formotion',
    // Nike
    'dri-fit', 'therma-fit', 'vaporknit', 'aeroswift', 'sphere', 'total 90',
    // General terms
    'authentic', 'player issue', 'player version', 'match worn', 'replica',
    'stadium', 'home', 'away', 'third'
];

// Named color mapping
const COLOR_MAP: { name: string; rgb: [number, number, number]; tolerance: number }[] = [
    { name: 'red', rgb: [200, 30, 30], tolerance: 60 },
    { name: 'blue', rgb: [30, 60, 180], tolerance: 60 },
    { name: 'navy', rgb: [20, 30, 80], tolerance: 40 },
    { name: 'white', rgb: [240, 240, 240], tolerance: 30 },
    { name: 'black', rgb: [30, 30, 30], tolerance: 40 },
    { name: 'yellow', rgb: [230, 200, 30], tolerance: 50 },
    { name: 'green', rgb: [30, 150, 60], tolerance: 60 },
    { name: 'orange', rgb: [230, 120, 30], tolerance: 50 },
    { name: 'purple', rgb: [100, 40, 140], tolerance: 50 },
    { name: 'pink', rgb: [230, 100, 150], tolerance: 50 },
    { name: 'grey', rgb: [130, 130, 130], tolerance: 40 },
    { name: 'gold', rgb: [200, 170, 50], tolerance: 50 },
];

// ============================================
// Color Extraction
// ============================================

/**
 * Extract the dominant color from an image
 * Uses Canvas to sample the center region (where kit color is most likely)
 */
export async function extractDominantColor(imageSource: string | File): Promise<{
    color: string;
    rgb: [number, number, number];
    confidence: number;
}> {
    return new Promise((resolve, reject) => {
        const img = new Image();
        img.crossOrigin = 'anonymous';

        img.onload = () => {
            try {
                const canvas = document.createElement('canvas');
                const ctx = canvas.getContext('2d', { willReadFrequently: true });
                if (!ctx) {
                    reject(new Error('Could not get canvas context'));
                    return;
                }

                // Resize for performance
                const maxSize = 200;
                const scale = Math.min(maxSize / img.width, maxSize / img.height);
                canvas.width = img.width * scale;
                canvas.height = img.height * scale;

                ctx.drawImage(img, 0, 0, canvas.width, canvas.height);

                // Sample center region (40-60% of image) to avoid badges/sponsors
                const sampleX = Math.floor(canvas.width * 0.3);
                const sampleY = Math.floor(canvas.height * 0.3);
                const sampleW = Math.floor(canvas.width * 0.4);
                const sampleH = Math.floor(canvas.height * 0.4);

                const imageData = ctx.getImageData(sampleX, sampleY, sampleW, sampleH);
                const data = imageData.data;

                // Calculate average color
                let totalR = 0, totalG = 0, totalB = 0;
                let pixelCount = 0;

                for (let i = 0; i < data.length; i += 4) {
                    // Skip very dark or very light pixels (likely shadows/highlights)
                    const r = data[i];
                    const g = data[i + 1];
                    const b = data[i + 2];
                    const brightness = (r + g + b) / 3;

                    if (brightness > 20 && brightness < 240) {
                        totalR += r;
                        totalG += g;
                        totalB += b;
                        pixelCount++;
                    }
                }

                if (pixelCount === 0) {
                    resolve({ color: 'unknown', rgb: [128, 128, 128], confidence: 0 });
                    return;
                }

                const avgR = Math.round(totalR / pixelCount);
                const avgG = Math.round(totalG / pixelCount);
                const avgB = Math.round(totalB / pixelCount);

                // Find closest named color
                let bestMatch = 'unknown';
                let bestDistance = Infinity;

                for (const colorDef of COLOR_MAP) {
                    const distance = Math.sqrt(
                        Math.pow(avgR - colorDef.rgb[0], 2) +
                        Math.pow(avgG - colorDef.rgb[1], 2) +
                        Math.pow(avgB - colorDef.rgb[2], 2)
                    );

                    if (distance < colorDef.tolerance && distance < bestDistance) {
                        bestMatch = colorDef.name;
                        bestDistance = distance;
                    }
                }

                // Calculate confidence (inverse of distance, capped at 100)
                const confidence = bestMatch === 'unknown'
                    ? 0
                    : Math.max(0, Math.min(100, 100 - (bestDistance * 2)));

                resolve({
                    color: bestMatch,
                    rgb: [avgR, avgG, avgB],
                    confidence
                });

            } catch (error) {
                reject(error);
            }
        };

        img.onerror = () => reject(new Error('Failed to load image'));

        // Handle different input types
        if (typeof imageSource === 'string') {
            img.src = imageSource;
        } else {
            img.src = URL.createObjectURL(imageSource);
        }
    });
}

// ============================================
// Text Detection (Sponsor & Technology)
// ============================================

/**
 * Detect sponsor name from OCR text
 */
export function detectSponsor(texts: string[]): string | null {
    const combined = texts.join(' ').toLowerCase();

    for (const sponsor of KNOWN_SPONSORS) {
        if (combined.includes(sponsor)) {
            // Return capitalized version
            return sponsor.split(' ')
                .map(word => word.charAt(0).toUpperCase() + word.slice(1))
                .join(' ');
        }
    }

    return null;
}

/**
 * Detect technology from OCR text
 */
export function detectTechnology(texts: string[]): string | null {
    const combined = texts.join(' ').toLowerCase();

    for (const tech of KNOWN_TECHNOLOGIES) {
        if (combined.includes(tech)) {
            // Return uppercase for tech names
            return tech.toUpperCase();
        }
    }

    return null;
}

// ============================================
// Main Analysis Function
// ============================================

/**
 * Analyze an image and extract visual data for cross-validation
 */
export async function analyzeImage(
    imageSource: string | File,
    ocrTexts?: string[]
): Promise<ImageAnalysisResult> {
    try {
        // Extract dominant color
        const colorResult = await extractDominantColor(imageSource);

        // Detect sponsor and technology from OCR texts (if provided)
        const sponsorHint = ocrTexts ? detectSponsor(ocrTexts) : null;
        const technologyHint = ocrTexts ? detectTechnology(ocrTexts) : null;

        return {
            dominantColor: colorResult.color !== 'unknown' ? colorResult.color : null,
            dominantColorRgb: colorResult.rgb,
            detectedTexts: ocrTexts || [],
            sponsorHint,
            technologyHint,
            colorConfidence: colorResult.confidence,
            analysisComplete: true
        };

    } catch (error) {
        console.error('Image analysis error:', error);
        return {
            dominantColor: null,
            dominantColorRgb: null,
            detectedTexts: [],
            sponsorHint: null,
            technologyHint: null,
            colorConfidence: 0,
            analysisComplete: false
        };
    }
}

/**
 * Quick color check - just extract dominant color without full analysis
 */
export async function quickColorCheck(imageSource: string | File): Promise<string | null> {
    try {
        const result = await extractDominantColor(imageSource);
        return result.confidence > 50 ? result.color : null;
    } catch {
        return null;
    }
}
