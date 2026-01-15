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

## Cost Estimates (Monthly)
| Service | Free Tier | Phase 1 Est. | Notes |
|---------|-----------|--------------|-------|
| Vercel | 100GB BW | $0-20 | Per-seat if team grows |
| Supabase | 500MB DB, 1GB storage | $0-25 | Pro at 8GB |
| OpenAI GPT-4o | - | $0.01-0.03/valuation | ~1K tokens/call |
| Lemon Squeezy | 5% + $0.50 | Variable | MoR included |
| Plausible | - | $9/mo | Optional, can use free |
| **Total** | **$0** | **$20-60/mo** | Before revenue |

## Technology Stack

### Frontend
| Layer | Technology | Reason |
|-------|------------|--------|
| Marketing | **Astro 5** | Static-first, LCP < 1s, pSEO pages |
| App | **Next.js 15** | React Server Components, App Router |
| Styling | **Tailwind CSS** | Utility-first, dark mode support |
| Components | Custom + Shadcn/UI | Consistent design system |

### Backend
| Layer | Technology | Reason |
|-------|------------|--------|
| Database | **Supabase** (PostgreSQL) | Auth included, realtime, free tier |
| Auth | **Supabase Auth** | Magic links, OAuth, simple |
| Storage | **Supabase Storage** | User photo uploads |
| API | **Next.js API Routes** | Serverless, co-located |

### AI & Processing
| Layer | Technology | Reason |
|-------|------------|--------|
| Vision AI | **OpenAI GPT-4o** | Best image analysis, affordable |
| Cost protection | Token tracking | Per-user usage limits |

### Payments
| Layer | Technology | Reason |
|-------|------------|--------|
| Billing | **Lemon Squeezy** | MoR (handles tax/VAT), subscription + one-time |
| Webhooks | Next.js API | Sync subscription status |

### Infrastructure
| Layer | Technology | Reason |
|-------|------------|--------|
| Hosting | **Vercel** | Edge functions, preview deploys |
| Domain | TBD (kitticker.com?) | Need to purchase |
| Analytics | **Plausible** | Privacy-first, simple |

## Current Phase: 1 - MVP

```
Phase 0: Landing page only (Astro) ✅ DONE
Phase 1: MVP app dashboard (Next.js) ← CURRENT
Phase 2: Advanced features (certificates, API)
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
