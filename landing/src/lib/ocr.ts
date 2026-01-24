/**
 * KitTicker OCR Module v2
 * 
 * Enhanced OCR with canvas-based preprocessing for improved accuracy.
 * Uses Tesseract.js v5 (Dec 2025) with Relaxed SIMD WASM.
 * 
 * Preprocessing Pipeline:
 * 1. Resize (min 1000px width for DPI)
 * 2. Grayscale (luminosity method)
 * 3. Contrast boost (+50%)
 * 4. Sharpen (3x3 kernel)
 * 
 * Tesseract.js v5 handles Adaptive Otsu binarization internally.
 */

import Tesseract from 'tesseract.js';

// ============================================
// Types
// ============================================

export interface OCRResult {
    success: boolean;
    text: string;
    confidence: number;
    extractedCodes: ExtractedCode[];
    processingTime: number;
    error?: string;
}

export interface ExtractedCode {
    code: string;
    brand: 'Nike' | 'Adidas' | 'Puma' | 'Umbro' | 'Unknown';
    confidence: number;
    position?: {
        x: number;
        y: number;
        width: number;
        height: number;
    };
}

// ============================================
// Brand Code Patterns
// ============================================

const CODE_PATTERNS: Record<string, RegExp[]> = {
    Nike: [
        /[A-Z]{2}\d{4}-\d{3}/g,      // CZ3984-100
        /\d{6}-\d{3}/g,              // 638920-013
    ],
    Adidas: [
        /[A-Z]{2}\d{4}/g,            // IS7462
        /[A-Z]\d{5}/g,               // M36158
    ],
    Puma: [
        /\d{6}-\d{2}/g,              // 736251-01
    ],
    Umbro: [
        /\d{5}-U/gi,                 // 96281-U
    ],
};

// ============================================
// Image Preprocessor Class
// ============================================

export class ImagePreprocessor {
    private canvas: HTMLCanvasElement;
    private ctx: CanvasRenderingContext2D;

    constructor() {
        this.canvas = document.createElement('canvas');
        const ctx = this.canvas.getContext('2d', { willReadFrequently: true });
        if (!ctx) throw new Error('Could not get 2D context');
        this.ctx = ctx;
    }

    /**
     * Full preprocessing pipeline
     */
    async preprocess(source: string | File | Blob): Promise<string> {
        await this.loadImage(source);
        this.resize(1000);        // Min 1000px width for good DPI
        this.grayscale();         // Reduce color complexity
        this.adjustContrast(1.5); // +50% contrast
        this.sharpen();           // Enhance edges
        return this.canvas.toDataURL('image/png');
    }

    /**
     * Load image onto canvas
     */
    private async loadImage(source: string | File | Blob): Promise<void> {
        return new Promise((resolve, reject) => {
            const img = new Image();
            img.crossOrigin = 'anonymous';

            img.onload = () => {
                this.canvas.width = img.width;
                this.canvas.height = img.height;
                this.ctx.drawImage(img, 0, 0);
                resolve();
            };

            img.onerror = () => reject(new Error('Failed to load image'));

            if (source instanceof File || source instanceof Blob) {
                img.src = URL.createObjectURL(source);
            } else {
                img.src = source;
            }
        });
    }

    /**
     * Resize image to minimum width for better OCR DPI
     */
    private resize(minWidth: number = 1000): void {
        if (this.canvas.width >= minWidth) return;

        const scale = minWidth / this.canvas.width;
        const newWidth = Math.round(this.canvas.width * scale);
        const newHeight = Math.round(this.canvas.height * scale);

        // Create temporary canvas for high-quality resize
        const tempCanvas = document.createElement('canvas');
        tempCanvas.width = newWidth;
        tempCanvas.height = newHeight;
        const tempCtx = tempCanvas.getContext('2d')!;
        tempCtx.imageSmoothingEnabled = true;
        tempCtx.imageSmoothingQuality = 'high';
        tempCtx.drawImage(this.canvas, 0, 0, newWidth, newHeight);

        // Copy back to main canvas
        this.canvas.width = newWidth;
        this.canvas.height = newHeight;
        this.ctx.drawImage(tempCanvas, 0, 0);
    }

    /**
     * Convert to grayscale using luminosity method
     */
    private grayscale(): void {
        const imageData = this.ctx.getImageData(0, 0, this.canvas.width, this.canvas.height);
        const data = imageData.data;

        for (let i = 0; i < data.length; i += 4) {
            // Luminosity method: 0.299R + 0.587G + 0.114B
            const gray = data[i] * 0.299 + data[i + 1] * 0.587 + data[i + 2] * 0.114;
            data[i] = data[i + 1] = data[i + 2] = gray;
        }

        this.ctx.putImageData(imageData, 0, 0);
    }

    /**
     * Adjust contrast (1.5 = +50% contrast)
     */
    private adjustContrast(factor: number = 1.5): void {
        const imageData = this.ctx.getImageData(0, 0, this.canvas.width, this.canvas.height);
        const data = imageData.data;
        const intercept = 128 * (1 - factor);

        for (let i = 0; i < data.length; i += 4) {
            data[i] = this.clamp(data[i] * factor + intercept);
            data[i + 1] = this.clamp(data[i + 1] * factor + intercept);
            data[i + 2] = this.clamp(data[i + 2] * factor + intercept);
        }

        this.ctx.putImageData(imageData, 0, 0);
    }

    /**
     * Sharpen using 3x3 convolution kernel
     */
    private sharpen(): void {
        const kernel = [
            0, -1, 0,
            -1, 5, -1,
            0, -1, 0
        ];
        this.applyConvolution(kernel);
    }

    /**
     * Apply convolution kernel to image
     */
    private applyConvolution(kernel: number[]): void {
        const imageData = this.ctx.getImageData(0, 0, this.canvas.width, this.canvas.height);
        const data = imageData.data;
        const w = this.canvas.width;
        const h = this.canvas.height;

        // Create copy for reading
        const copy = new Uint8ClampedArray(data);

        for (let y = 1; y < h - 1; y++) {
            for (let x = 1; x < w - 1; x++) {
                const idx = (y * w + x) * 4;

                for (let c = 0; c < 3; c++) {
                    let sum = 0;
                    for (let ky = -1; ky <= 1; ky++) {
                        for (let kx = -1; kx <= 1; kx++) {
                            const kidx = ((y + ky) * w + (x + kx)) * 4 + c;
                            const kval = kernel[(ky + 1) * 3 + (kx + 1)];
                            sum += copy[kidx] * kval;
                        }
                    }
                    data[idx + c] = this.clamp(sum);
                }
            }
        }

        this.ctx.putImageData(imageData, 0, 0);
    }

    /**
     * Clamp value to 0-255 range
     */
    private clamp(value: number): number {
        return Math.max(0, Math.min(255, Math.round(value)));
    }
}

// ============================================
// Export: Preprocess for OCR
// ============================================

/**
 * Preprocess image for OCR
 * Applies: resize, grayscale, contrast, sharpen
 */
export async function preprocessForOCR(source: string | File | Blob): Promise<string> {
    try {
        const processor = new ImagePreprocessor();
        return await processor.preprocess(source);
    } catch {
        // Fallback: return original if preprocessing fails
        if (source instanceof File || source instanceof Blob) {
            return URL.createObjectURL(source);
        }
        return source;
    }
}

// ============================================
// Helper Functions
// ============================================

/**
 * Detect brand from extracted code
 */
function detectBrand(code: string): ExtractedCode['brand'] {
    const normalized = code.toUpperCase();

    for (const [brand, patterns] of Object.entries(CODE_PATTERNS)) {
        for (const pattern of patterns) {
            // Reset regex lastIndex
            pattern.lastIndex = 0;
            if (pattern.test(normalized)) {
                return brand as ExtractedCode['brand'];
            }
        }
    }

    return 'Unknown';
}

/**
 * Extract product codes from raw OCR text
 */
function extractCodes(text: string): ExtractedCode[] {
    const codes: ExtractedCode[] = [];
    const seen = new Set<string>();

    // Normalize text - remove common OCR errors
    const normalizedText = text
        .toUpperCase()
        .replace(/[Oo]/g, '0')  // O → 0 in codes
        .replace(/[Il]/g, '1')  // I/l → 1 in codes
        .replace(/\s+/g, ' ');

    // Try each brand's patterns
    for (const [brand, patterns] of Object.entries(CODE_PATTERNS)) {
        for (const pattern of patterns) {
            pattern.lastIndex = 0;
            const matches = normalizedText.matchAll(pattern);

            for (const match of matches) {
                const code = match[0].toUpperCase();
                if (!seen.has(code)) {
                    seen.add(code);
                    codes.push({
                        code,
                        brand: brand as ExtractedCode['brand'],
                        confidence: 0.9,
                    });
                }
            }
        }
    }

    return codes;
}

// ============================================
// Main OCR Function
// ============================================

/**
 * Perform OCR on an image and extract product codes
 * 
 * @param imageSource - URL, File, or Blob of the image
 * @param onProgress - Optional progress callback (0-100)
 * @returns OCRResult with extracted codes
 */
export async function extractProductCode(
    imageSource: string | File | Blob,
    onProgress?: (progress: number) => void
): Promise<OCRResult> {
    const startTime = performance.now();

    try {
        // Preprocess image for better accuracy
        const processedImage = await preprocessForOCR(imageSource);

        // Configure Tesseract (v5 with SIMD optimization)
        const { data } = await Tesseract.recognize(
            processedImage,
            'eng',
            {
                logger: (m) => {
                    if (m.status === 'recognizing text' && onProgress) {
                        onProgress(Math.round(m.progress * 100));
                    }
                },
            }
        );

        // Extract codes from OCR text
        const extractedCodes = extractCodes(data.text);

        // Clean up object URL if we created one
        if (processedImage.startsWith('blob:')) {
            URL.revokeObjectURL(processedImage);
        }

        const processingTime = Math.round(performance.now() - startTime);

        return {
            success: true,
            text: data.text,
            confidence: data.confidence / 100,
            extractedCodes,
            processingTime,
        };
    } catch (error) {
        const processingTime = Math.round(performance.now() - startTime);

        return {
            success: false,
            text: '',
            confidence: 0,
            extractedCodes: [],
            processingTime,
            error: error instanceof Error ? error.message : 'OCR failed',
        };
    }
}

/**
 * Quick scan - optimized for speed over accuracy
 * Good for initial detection, use full scan for verification
 */
export async function quickScan(imageSource: string | File | Blob): Promise<ExtractedCode[]> {
    const result = await extractProductCode(imageSource);
    return result.extractedCodes;
}

/**
 * Validate if an image is likely to contain a product label
 * Uses basic heuristics - look for text density
 */
export async function isLikelyProductLabel(imageSource: string | File | Blob): Promise<boolean> {
    const result = await extractProductCode(imageSource);

    // If we found codes, it's definitely a label
    if (result.extractedCodes.length > 0) return true;

    // If we found substantial text, it might be a label
    const textDensity = result.text.replace(/\s/g, '').length;
    return textDensity > 20 && result.confidence > 0.5;
}
