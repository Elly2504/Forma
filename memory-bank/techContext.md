# KitTicker - Technical Context

## Architecture Overview

**Multi-zone monorepo structure:**

```
Forma/
├── landing/          # Astro (marketing, pSEO) ✅ ACTIVE
├── app/              # Next.js 15 (MVP)        ✅ ACTIVE
├── packages/         # Shared code            📋 PLANNED
│   ├── ui/           # Component library
│   └── config/       # Shared configs
└── memory-bank/      # Documentation          ✅ ACTIVE
```

## Cost Engineering: The Scalability Trap

> **Warning:** API costs are an existential threat. $0.01-0.05/image × 1000 users × 5/day = **$1,500-7,500/month loss**

### Hybrid Architecture (4-Step Cost Optimization)

| Step | Layer | Technology | Cost | Purpose |
|------|-------|------------|------|---------|
| 1 | On-Device | TensorFlow.js / CoreML | $0 | Image quality check, shirt detection |
| 2 | Cheap Classification | YOLOv8 (Hetzner GPU) | Low | Basic brand/team classification |
| 3 | Premium API | GPT-4o Vision | Per-call | Product code OCR only (cropped region) |
| 4 | Caching | PostgreSQL | $0 | Verified codes → Future lookups free |

**Key Insight:** Product Code (MPN) verification = 80% accuracy for post-2000 shirts, very cheap.

### Cost Estimates (Monthly)
| Service | Free Tier | Phase 1 Est. | Optimized Est. | Notes |
|---------|-----------|--------------|----------------|-------|
| Vercel | 100GB BW | $0-20 | $0-20 | Per-seat if team grows |
| Supabase | 500MB DB, 1GB storage | $0-25 | $0-25 | Pro at 8GB |
| OpenAI GPT-4o | - | $150-500 | **$20-50** | With hybrid architecture |
| Hetzner GPU | - | $0 | $30-50 | Self-hosted classification |
| Lemon Squeezy | 5% + $0.50 | Variable | Variable | MoR included |
| Plausible | - | $9/mo | $9/mo | Optional |
| **Total** | **$0** | **$180-550/mo** | **$60-150/mo** | Hybrid saves 70% |

## Technology Stack

### Frontend
| Layer | Technology | Reason |
|-------|------------|--------|
| Marketing | **Astro 5** | Static-first, LCP < 1s, pSEO pages |
| App | **Next.js 15** | React Server Components, App Router |
| Styling | **Tailwind CSS** | Utility-first, dark mode support |
| Components | Custom + Shadcn/UI | Consistent design system |
| On-Device ML | **TensorFlow.js** | Pre-filter bad images, $0 cost |

### Backend
| Layer | Technology | Reason |
|-------|------------|--------|
| Database | **Supabase** (PostgreSQL) | Auth included, realtime, free tier |
| Auth | **Supabase Auth** | Magic links, OAuth, simple |
| Storage | **Supabase Storage** | User photo uploads |
| API | **Next.js API Routes** | Serverless, co-located |
| Caching | **Supabase/Postgres** | Product code lookup cache |

### AI & Processing
| Layer | Technology | Reason |
|-------|------------|--------|
| Vision AI | **OpenAI GPT-4o** | Best image analysis (for OCR only) |
| Classification | **YOLOv8** (optional) | Self-hosted, low cost |
| Cost protection | Token tracking + Caching | Per-user limits + code cache |

### Payments
| Layer | Technology | Reason |
|-------|------------|--------|
| Billing | **Lemon Squeezy** | MoR (handles tax/VAT), subscription + credits |
| Webhooks | Next.js API | Sync subscription + credit balance |

### Infrastructure
| Layer | Technology | Reason |
|-------|------------|--------|
| Hosting | **Vercel** | Edge functions, preview deploys |
| Domain | TBD (kitticker.com?) | Need to purchase |
| Analytics | **Plausible** | Privacy-first, simple |
| GPU (optional) | **Hetzner** | Self-hosted models, €30-50/mo |

## Current Phase: 1 - Content Moat + Low-Tech MVP

```
Phase 0: Landing page only (Astro) ✅ DONE
Phase 1: Content Moat + Low-Tech MVP ← CURRENT
  - Content: "Wikipedia of Product Codes"
  - Tech: Label/Product Code OCR
Phase 2: High-Tech Vision (custom CV model, Sold Price API)
Phase 3: Marketplace
```

## Environment Variables (Future)
```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=

# OpenAI
OPENAI_API_KEY=

# Lemon Squeezy
LEMONSQUEEZY_API_KEY=
LEMONSQUEEZY_WEBHOOK_SECRET=
```

## Local Development
```bash
# Landing page
cd landing && npm run dev    # http://localhost:4321

# App
cd app && npm run dev        # http://localhost:3000
```

## Data Strategy: Product Codes

> **Key Insight:** Training AI on fakes is hard (banned from marketplaces). Product Code verification is the "low-tech" but highly accurate proxy.

| Era | Verification Strategy |
|-----|----------------------|
| Post-2000 | **Product Code (MPN)** — Nike/Adidas codes are unique, fakes use wrong/generic codes |
| Pre-2000 | **Visual Analysis** — Requires custom trained model (Phase 2) |

### The Code Database Moat
```typescript
interface ProductCode {
  code: string;           // e.g., "847284-010"
  brand: 'Nike' | 'Adidas' | 'Umbro' | ...;
  team: string;           // e.g., "Paris Saint-Germain"
  year: number;           // e.g., 2016
  type: 'Home' | 'Away' | 'Third' | 'GK';
  verified: boolean;
  verifiedBy: 'community' | 'official';
  createdAt: Date;
}
```

**Moat:** Once code is verified, future lookups cost $0.
