# KitTicker - Technical Context

## Architecture: API-First Platform

```
┌─────────────────────────────────────────────────────────────────┐
│                    KitTicker Data Platform                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │   PUBLIC     │    │  MARKETING   │    │    DATA      │       │
│  │    API       │    │    SITE      │    │    STORE     │       │
│  │  (Vercel)    │    │   (Astro)    │    │  (Supabase)  │       │
│  └──────┬───────┘    └──────────────┘    └──────┬───────┘       │
│         │                                        │               │
│         └────────────────┬───────────────────────┘               │
│                          │                                       │
│               ┌──────────▼──────────┐                           │
│               │   Core Services     │                           │
│               │  - api-keys.ts      │                           │
│               │  - verifier.ts      │                           │
│               │  - dpp.ts           │                           │
│               └─────────────────────┘                           │
└─────────────────────────────────────────────────────────────────┘


External Clients (Retailers, Platforms)
           │
           ▼
    GET /api/v1/codes/lookup?code=CZ3984-100
           │
           ▼
    ┌─────────────────┐
    │  API Response   │
    │  + Rate Limit   │
    │  + Usage Log    │
    └─────────────────┘
```

---

## Directory Structure

```
Forma/
├── landing/                  # Astro (marketing + API)
│   ├── src/
│   │   ├── components/       # UI components (see below)
│   │   ├── lib/              # Core modules
│   │   │   ├── api-keys.ts   # API key management
│   │   │   ├── api-types.ts  # TypeScript interfaces
│   │   │   ├── dpp.ts        # Digital Product Passport
│   │   │   ├── ocr.ts        # Tesseract.js OCR
│   │   │   ├── supabase.ts   # DB client
│   │   │   ├── verifier.ts   # Multi-signal auth (1468 lines)
│   │   │   └── image-analyzer.ts  # Visual extraction
│   │   └── pages/
│   │       ├── api/v1/       # SSR API endpoints ✅ LIVE
│   │       ├── how-it-works.astro  # 8 sections ✅ NEW
│   │       └── dpp.astro          # 7 sections ✅ NEW
│   └── supabase-schema.sql   # Database schema
├── app/                      # Next.js 15 (future dashboard)
└── memory-bank/              # Documentation ✅ ACTIVE
```

### Key UI Components (Session 28-29)

**How It Works Page:**
- `ProcessPipeline.astro` - 4-step animated flow
- `AIAnalysisVisual.astro` - Image extraction demo
- `CheckpointGrid.astro` - 11 checkpoints with weights
- `FakeDetectionCompare.astro` - Authentic vs Fake
- `DPPPreview.astro` - Certificate preview
- `CompetitorTable.astro` - Comparison table

**DPP Page:**
- `DPPProcessFlow.astro` - Verify → Generate → Certify → Transfer
- `DPPCertificateDemo.astro` - Interactive certificate
- `DPPUseCases.astro` - Retailers, Clubs, Marketplaces
- `DPPIntegration.astro` - API code example

---

## Technology Stack

### API Layer
| Component | Technology | Purpose |
|-----------|------------|---------|
| Runtime | **Astro + Vercel SSR** | Hybrid static + SSR API |
| Endpoints | API Routes (`pages/api/`) | RESTful JSON API |
| Auth | **API Keys** (SHA-256 hash) | B2B authentication |
| Rate Limiting | Tier-based quotas | Prevent abuse |

### Data Layer
| Component | Technology | Purpose |
|-----------|------------|---------|
| Database | **Supabase (PostgreSQL)** | Primary data store |
| Tables | `product_codes`, `api_keys`, `digital_passports` | Core entities |
| Caching | PostgreSQL + API response cache | Speed optimization |
| Functions | PL/pgSQL (`check_api_quota()`) | Server-side logic |

### Security
| Component | Technology | Purpose |
|-----------|------------|---------|
| Key Hashing | **Web Crypto API (SHA-256)** | Secure key storage |
| RLS | Supabase Row Level Security | Data isolation |
| Logging | `api_usage_logs` table | Audit trail |

### Frontend (Marketing)
| Component | Technology | Purpose |
|-----------|------------|---------|
| Site Generator | **Astro 5** | Static-first marketing |
| Styling | **Tailwind CSS** | Utility-first CSS |
| Content | **MDX** | Blog & guides |

---

## API Endpoints (Live)

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/v1/health` | GET | ❌ | Health check |
| `/api/v1/codes/lookup` | GET | ✅ | Single code lookup |
| `/api/v1/codes/validate` | POST | ✅ | Batch validation (starter+) |
| `/api/v1/verify` | POST | ✅ | Multi-signal + cross-validation |
| `/api/v1/dpp/generate` | POST | ✅ | Create DPP (business+) |
| `/api/v1/dpp/[uid]` | GET | ❌ | Public DPP lookup |

---

## Database Schema (Supabase)

### Core Tables

```sql
-- Product codes (the data moat)
product_codes (
  id, uid, code, brand, team, season, kit_type, variant,
  verified, verification_source, image_url, thumbnail_url,
  estimated_price_min, estimated_price_max, price_currency,
  primary_color, secondary_color, pattern,
  lookup_count, api_lookup_count, created_at, updated_at
)

-- API key management
api_keys (
  id, key_prefix, key_hash, owner_email, company_name,
  tier, rate_limit, monthly_quota, usage_this_month,
  is_active, created_at, last_used_at
)

-- Digital Product Passports
digital_passports (
  id, uid, product_code_id, owner_email, owner_name,
  verification_status, authenticity_evidence,
  transfer_history, qr_code_url, nfc_data, created_at
)
```

---

## Environment Variables

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://sjltydrpwavzrrmoaivt.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=xxxx
SUPABASE_SERVICE_ROLE_KEY=xxxx

# Future integrations
OPENAI_API_KEY=xxxx          # For visual AI (Phase 2)
LEMONSQUEEZY_API_KEY=xxxx    # For billing
```

---

## Development Commands

```bash
# Local development
cd landing && npm run dev       # http://localhost:4321

# Build & deploy
cd landing && vercel --prod --yes

# Database
# Run supabase-schema.sql in Supabase Dashboard SQL Editor
```

---

## Cost Model (API-First)

| Component | Cost | Notes |
|-----------|------|-------|
| Vercel (SSR) | $0-20/mo | Free tier covers initial scale |
| Supabase | $0-25/mo | Free tier → Pro at scale |
| API Revenue | +$500-15K/mo | Subscription + overage |
| **Net Margin** | **High** | Data is infinitely replicable |

**Key insight:** Once a product code is verified, future lookups cost effectively $0.
