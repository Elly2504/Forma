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

### 2. Hybrid Pricing Model
```
Subscription (base access) + Credits (usage-based)
```

**Pattern:**
- Subscription tiers gate feature access
- Each valuation consumes 1 credit
- Overage charged at $0.30/credit
- Prevents AI cost blowout

**Implementation:**
```typescript
interface User {
  tier: 'free' | 'collector' | 'dealer';
  monthlyCredits: number;
  creditsUsed: number;
  extraCredits: number;  // purchased credit packs
}
```

### 3. Token Tracking for AI Costs
Every GPT-4o call is tracked:
```typescript
interface ValuationLog {
  userId: string;
  inputTokens: number;
  outputTokens: number;
  estimatedCost: number;
  timestamp: Date;
}
```

**Budget protection:**
- Hard limit per user per month
- Alert at 80% usage
- Graceful degradation (not hard failure)

### 4. Design System Tokens

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

**Gradients:**
```css
--gold-gradient: linear-gradient(135deg, #fbbf24, #d97706);
```

### 5. Component Patterns

**Glass Cards:**
```css
.glass-card {
  background: rgba(17, 17, 17, 0.8);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(245, 158, 11, 0.1);
  border-radius: 16px;
}
```

**Responsive Breakpoints:**
```css
sm: 640px   /* Mobile landscape */
md: 768px   /* Tablet */
lg: 1024px  /* Desktop */
xl: 1280px  /* Large desktop */
```

**Grid Pattern:**
- Mobile: 1 column
- Tablet (768px): 2 columns for features, stack for pricing
- Desktop (1024px+): 3 columns

### 6. Data Flow (Future MVP)

```
User uploads photos
       ↓
Supabase Storage (presigned URLs)
       ↓
Next.js API Route
       ↓
GPT-4o Vision API
       ↓
Parse response → Store in DB
       ↓
Return valuation to user
       ↓
Decrement user credits
```

### 7. Error Handling Pattern
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

### 8. File Naming Conventions
| Type | Convention | Example |
|------|------------|---------|
| Components | PascalCase | `WaitlistForm.tsx` |
| Pages | kebab-case | `how-it-works.astro` |
| Utilities | camelCase | `formatCurrency.ts` |
| Types | PascalCase | `Valuation.ts` |

### 9. Security Patterns
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

**Rules:**
- API keys: Server-side only, never in client bundle
- User input: Always validate/sanitize
- File uploads: Validate type, size, scan for malware
- Auth: Require for all mutations

### 10. Testing Strategy
| Layer | Tool | Coverage Target |
|-------|------|-----------------|
| Unit | Vitest | 80% |
| Integration | Vitest + MSW | Key flows |
| E2E | Playwright | Critical paths |
| Visual | Percy (optional) | UI regressions |

```bash
# Commands
npm run test          # Unit tests
npm run test:e2e      # Playwright
npm run test:coverage # With coverage
```
