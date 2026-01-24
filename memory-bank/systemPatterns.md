# KitTicker - System Patterns

## Architecture Decisions

### 1. API-First Design

> **"Build for machines first, humans second."**

Every feature is designed as an API endpoint first. The marketing site and future dashboard are consumers of the same API that external clients use.

```
External Client ──┐
                  ├──▶ /api/v1/* ──▶ Supabase
Internal Site ────┘
```

### 2. Hybrid SSR Mode (Astro + Vercel)

```typescript
// astro.config.mjs
export default defineConfig({
  output: 'server',  // Enable SSR for API routes
  adapter: vercel(),
});

// All API files require:
export const prerender = false;  // SSR at runtime
```

**Why?**
- Static pages for marketing (LCP < 1s)
- SSR for API endpoints (dynamic data)
- Single codebase, unified deployment

### 3. API Key Authentication Pattern

```typescript
// Request
Authorization: Bearer kt_live_xxxxxxxxxxxxxxxxxxxx

// Validation flow
1. Extract key from header
2. Hash with SHA-256 (Web Crypto API)
3. Lookup in api_keys table
4. Check is_active and tier
5. Verify quota not exceeded
6. Increment usage counter
7. Log request to api_usage_logs
```

**Key format:** `kt_live_` + 48 random hex chars

### 4. Tier-Based Response Filtering

```typescript
const tier = apiKey.tier;

const response = {
  code: product.code,           // All tiers
  brand: product.brand,         // All tiers
  team: product.team,           // All tiers
  season: product.season,       // All tiers
  image_url: tier !== 'free' ? product.image_url : undefined,  // Starter+
  estimated_price: tier === 'business' ? product.price : undefined, // Business+
};
```

### 5. Data Defense (Cross-Validation)

> **The Logical Layer of Security**

Fakes often use valid codes but on wrong kit variants. We catch this by cross-validating:

```typescript
async function crossValidateCodeVsVisual(code: string, visual: VisualAttributes) {
  const expected = await getProductByCode(code);
  
  const mismatches: string[] = [];
  
  if (visual.primary_color && expected.primary_color !== visual.primary_color) {
    mismatches.push(`Color: expected ${expected.primary_color}, got ${visual.primary_color}`);
  }
  
  if (visual.kit_type && expected.kit_type !== visual.kit_type) {
    mismatches.push(`Kit type: expected ${expected.kit_type}, got ${visual.kit_type}`);
  }
  
  return {
    passed: mismatches.length === 0,
    mismatches,
  };
}
```

### 6. Digital Product Passport (DPP) Pattern

```typescript
// UID format: KT-YYYY-XXXXXX
function generateDppUid(): string {
  const year = new Date().getFullYear();
  const random = crypto.getRandomValues(new Uint8Array(3))
    .reduce((acc, byte) => acc + byte.toString(16).padStart(2, '0'), '');
  return `KT-${year}-${random.toUpperCase()}`;
}
```

**DPP lifecycle:**
```
1. Retailer calls POST /api/v1/dpp/generate
2. New UID created (KT-2026-XXXXXX)
3. QR code URL generated
4. DPP stored in digital_passports table
5. Anyone can lookup via GET /api/v1/dpp/{uid}
```

### 7. Multi-Signal Authentication

```typescript
// Signal weights (sum = 100%)
const SIGNAL_WEIGHTS = {
  database_match: 30,      // Code found in verified database
  blacklist_check: 25,     // Not on known fake codes list
  format_validation: 20,   // Matches brand's code format
  brand_consistency: 15,   // Brand filter matches result
  era_plausibility: 10,    // Year/season makes sense
};

// Confidence calculation
function calculateConfidence(signals: Signal[]): number {
  let weightedSum = 0;
  let totalWeight = 0;
  
  for (const signal of signals) {
    const score = signal.passed ? 1 : signal.value === 'warning' ? 0.5 : 0;
    weightedSum += score * signal.weight * signal.confidence;
    totalWeight += signal.weight * signal.confidence;
  }
  
  return Math.round((weightedSum / totalWeight) * 100);
}
```

### 8. Explainable AI Pattern

> **"Do not be a black box; be a magnifying glass."**

Every API response includes evidence:

```json
{
  "success": true,
  "data": {
    "verdict": "likely_authentic",
    "confidence": 87,
    "evidence": [
      {
        "signal": "database_match",
        "weight": 30,
        "passed": true,
        "details": "✓ Matches Nike PSG 2016/17 Third"
      }
    ]
  }
}
```

### 9. Usage Logging Pattern

```typescript
await supabase.from('api_usage_logs').insert({
  api_key_id: key.id,
  endpoint: '/v1/codes/lookup',
  method: 'GET',
  request_params: { code },
  response_status: 200,
  response_cached: false,
  latency_ms: Date.now() - startTime,
  ip_address: request.headers.get('x-forwarded-for'),
  user_agent: request.headers.get('user-agent'),
});
```

### 10. Error Response Pattern

```typescript
// Standard API error format
interface ApiError {
  success: false;
  error: string;
  request_id: string;
  quota?: {
    remaining: number;
    reset_date: string;
  };
}

// Usage
return new Response(JSON.stringify({
  success: false,
  error: 'Product code not found',
  request_id: crypto.randomUUID(),
}), { status: 404 });
```

---

## File Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| API Endpoints | kebab-case folders | `api/v1/codes/lookup.ts` |
| Lib modules | kebab-case files | `api-keys.ts`, `api-types.ts` |
| Components | PascalCase | `ProductCodeChecker.astro` |
| Types | PascalCase | `ApiKey`, `ProductCode` |

---

## Security Patterns

1. **Never store raw API keys** — Only SHA-256 hashes
2. **Rate limiting per tier** — Prevent abuse
3. **Request logging** — Full audit trail
4. **RLS on all tables** — Row Level Security
5. **CORS headers** — Configured per endpoint
6. **Input validation** — All user inputs sanitized

---

## OCR Preprocessing Pipeline

```typescript
// ocr.ts - ImagePreprocessor class
async preprocess(source: File | Blob): Promise<string> {
  await loadImage(source);
  resize(1000);        // Min 1000px width
  grayscale();         // Luminosity: 0.299R + 0.587G + 0.114B
  adjustContrast(1.5); // +50% contrast
  sharpen();           // 3x3 convolution kernel
  return canvas.toDataURL('image/png');
}
```

**Tesseract.js v5 (Dec 2025):**
- Relaxed SIMD WASM: 15-35% faster
- Built-in Adaptive Otsu binarization
- 54% smaller, 47% less memory

---

## Camera Scanner Pattern

```typescript
// CameraScanner.astro - Real-time code scanning
async function startCamera(facingMode: 'user' | 'environment') {
  const stream = await navigator.mediaDevices.getUserMedia({
    video: { facingMode, width: { ideal: 1280 } }
  });
  video.srcObject = stream;
  startScanning(); // 1 FPS OCR loop
}
```

**Features:**
- Back camera default for mobile
- Auto-verification on code detection
- Frame quality check before OCR

---

## UI Animation Patterns (2025)

```css
/* Verdict glow effects */
.verdict-glow-authentic { box-shadow: 0 0 20px rgba(16, 185, 129, 0.3); }
.verdict-glow-warning { box-shadow: 0 0 20px rgba(234, 179, 8, 0.3); }
.verdict-glow-fake { box-shadow: 0 0 20px rgba(239, 68, 68, 0.3); }

/* Confidence gauge with shimmer */
.confidence-gauge-fill::after {
  animation: shimmer 2s infinite;
}
```

**Animation Classes:**
- `animate-code-found`: Scale bounce
- `animate-bounce-in`: Entry animation
- `animate-shake`: Error feedback

