# KitTicker - System Patterns

## Architecture Decisions

### 1. Multi-Zone Separation
```
Marketing (Astro) ←→ App (Next.js)
     ↓                    ↓
  Static CDN          Serverless
```

**Why?**
- Astro: Lightning-fast marketing pages (LCP < 1s)
- Next.js: Dynamic app features with React Server Components
- Clean separation of concerns
- Independent deploy cycles

### 2. Explainable AI (Trust Pattern)

> **Core Principle:** "Do not be a black box; be a magnifying glass."

```typescript
// Bad Output
{ authentic: true, confidence: 0.98 }

// Good Output (Explainable)
{
  verdict: 'likely_authentic',
  confidence: 0.92,
  evidence: [
    { type: 'product_code', value: '847284-010', match: 'Nike 2016 PSG Home' },
    { type: 'logo_stitching', density: 12.4, reference: '12-13 stitches/cm' },
    { type: 'label_format', matches: true, era: '2015-2018' }
  ],
  warnings: [
    { type: 'fabric_wear', note: 'Minor pilling detected on collar' }
  ]
}
```

**Implementation:** Every AI decision must include evidence array.

### 3. Hybrid Pricing Model (Credit System)
```
Subscription (base access) + Credits (usage-based)
```

**Pattern:**
- Subscription tiers gate feature access
- Each valuation consumes 1 credit
- Overage charged at $0.30/credit
- **Aligns API cost with revenue** (CheckCheck model)

**Implementation:**
```typescript
interface User {
  tier: 'free' | 'collector' | 'dealer';
  monthlyCredits: number;
  creditsUsed: number;
  extraCredits: number;  // purchased credit packs
}
```

### 4. 4-Step Cost Optimization Pipeline

```
User Photo
    ↓
[Step 1: On-Device] TensorFlow.js
  - Is this a shirt? Is image clear?
  - Cost: $0
  - Reject 30% bad uploads
    ↓
[Step 2: Cheap Classification] Self-hosted YOLOv8
  - Brand detection, team guess
  - Cost: ~$0.001
    ↓
[Step 3: Premium API] GPT-4o Vision
  - Product code OCR ONLY (cropped region)
  - Cost: ~$0.01 (vs $0.05 full image)
    ↓
[Step 4: Cache Lookup] PostgreSQL
  - Code 847284-010 → "2016 PSG Home"
  - Cost: $0
  - Future lookups skip Step 3
```

**Savings:** 70% cost reduction vs naive API calls.

### 5. Token Tracking for AI Costs
Every GPT-4o call is tracked:
```typescript
interface ValuationLog {
  userId: string;
  inputTokens: number;
  outputTokens: number;
  estimatedCost: number;
  timestamp: Date;
  cached: boolean;  // If cached, cost = 0
}
```

**Budget protection:**
- Hard limit per user per month
- Alert at 80% usage
- Graceful degradation (not hard failure)

### 6. Product Code Cache (Data Moat)
```typescript
interface ProductCodeCache {
  code: string;           // Primary key
  brand: string;
  team: string;
  year: number;
  type: 'Home' | 'Away' | 'Third' | 'GK';
  verified: boolean;
  verifiedBy: 'community' | 'official' | 'ai';
  lookupCount: number;    // Track popularity
}
```

**Moat:** Every verified code becomes free forever.

### 7. Design System Tokens

**Color Palette (Dark Theme):**
```css
--bg-primary: #0a0a0a;
--bg-secondary: #111111;
--gold-400: #fbbf24;
--gold-500: #f59e0b;
--gold-600: #d97706;
--text-primary: #ffffff;
--text-secondary: #a1a1aa;
--text-muted: #71717a;
```

### 8. Error Handling Pattern
```typescript
// API responses
type ApiResponse<T> = 
  | { success: true; data: T }
  | { success: false; error: string; code: string };

// Usage
if (!response.success) {
  toast.error(response.error);
}
```

### 9. File Naming Conventions
| Type | Convention | Example |
|------|------------|---------|
| Components | PascalCase | `ValuationResult.tsx` |
| Pages | kebab-case | `how-it-works.astro` |
| Utilities | camelCase | `formatCurrency.ts` |
| Types | PascalCase | `Valuation.ts` |

### 10. Security Patterns
```typescript
// Rate limiting
const RATE_LIMITS = {
  valuations: { max: 10, windowMs: 60_000 },  // 10/min
  uploads: { max: 20, windowMs: 60_000 },
};

// Image validation
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_FILE_SIZE = 5 * 1024 * 1024;  // 5MB
```

### 11. Content-First Marketing Pattern
```
Phase 1: Build content (guides, product code database)
    ↓
Phase 2: SEO traffic + community trust
    ↓
Phase 3: Introduce tool as "helper" not "replacement"
    ↓
Phase 4: Monetize trusted user base
```

**Community Engagement:**
- Don't sell, help
- Post evidence in "Legit Check" threads
- Tool generates shareable reports → viral loop
