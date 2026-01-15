# KitTicker - Active Context

> **Last Updated:** 2026-01-15 23:05 (UTC+1)

## Current Focus
**Phase 1: MVP Launch** — Direkt dönüşüm stratejisi, waitlist kaldırıldı.

## Working On
Next.js app setup ve Supabase auth entegrasyonu.

## Recently Completed
- [x] **Strateji değişikliği:** Waitlist → Direct conversion (MVP + Free Trial)
- [x] Landing page CTA güncellemeleri (Hero, CTASection, Pricing, Header)
- [x] WaitlistForm.tsx kaldırıldı
- [x] Next.js 15 app setup (`app/` dizini)
- [x] Auth sayfaları (signup, login)
- [x] Dashboard sayfası
- [x] KitTicker design system (`globals.css`)

## Next Steps
1. **Domain satın al** — Devam ediyor
2. **Supabase projesi** — Auth, DB, Storage
3. **Auth entegrasyonu** — Signup/Login form bağlama
4. **GPT-4o entegrasyonu** — Valuation API
5. **Deploy** — Vercel'e landing + app deploy

## Blockers
None currently.

## Quick Commands
| Command | Action |
|---------|--------|
| `cd landing && npm run dev` | Start dev server (localhost:4321) |
| `npm run build` | Build for production |
| `vercel deploy` | Deploy to Vercel |

## Key Files
| File | Purpose |
|------|---------|
| `landing/src/pages/index.astro` | Main landing page |
| `landing/src/styles/global.css` | Landing design tokens |
| `app/src/app/globals.css` | App design system |
| `app/src/app/(auth)/signup/page.tsx` | Signup page |
| `app/src/app/(dashboard)/dashboard/page.tsx` | Dashboard |

## Decision Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-15 | Waitlist → MVP Direct Conversion | Müşteriyi kaybetmemek için hemen ürün denetmeli |
| 2026-01-14 | Use `lg:` breakpoint for 3-col grids | Tablet (768px) too narrow for 3 columns |
| 2026-01-14 | Astro for landing, Next.js for app | Optimal for each use case |
