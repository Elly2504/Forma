# KitTicker - Active Context

> **Last Updated:** 2026-01-17 14:28 (UTC+1)

## Current Focus
**Phase 1: Content Moat** — Build SEO authority and community trust BEFORE heavy tech investment.

## Strategic Shift
Based on comprehensive strategic analysis:
- **Content-First:** Build "Wikipedia of Product Codes" before full AI
- **Explainable AI:** Show evidence, not black box verdicts
- **Hybrid Architecture:** 4-step cost optimization (70% savings)
- **Trust Gap:** Win Purist collectors first, they validate for others

## Working On
1. ✅ pSEO Content Strategy implemented
2. ✅ 31 real authentication images integrated
3. ✅ Umbro Dating Guide (1980-2010) created
4. ✅ 12-week Content Calendar created
5. ✅ Mobile optimization complete
6. 🔜 Schema validation (Google Rich Results Test)
7. 🔜 PageSpeed Insights audit

## Recently Completed
- [x] **Mobile Optimization (Session 12):**
  - Hamburger menu with slide-out drawer
  - Responsive typography (3xl→5xl→7xl)
  - Text contrast improved (#a3a3a3 → #c4c4c4)
  - Header/Footer branding unified
  - Guides link added to navigation
- [x] **Content Creation (Session 11):**
  - "How to Date Umbro Shirts (1980-2010)" guide
  - 12-week content calendar (1 post/week)
  - New guide: 5 era sections, logo evolution, Dots Test, FAQ
  - Live at kitticker.com/guides/how-to-date-umbro-shirts
- [x] **Authentication Guide Images (Session 10):**
  - 31 Recraft AI generated images deployed
  - Nike (8): labels, swing tags, security, crest, swoosh
  - Adidas (8): labels, data matrix, swing tag, logo, comparison
  - Puma (7): labels, production date, logo detail
  - Umbro (7): logo evolution, vintage label (dots test!), fabric
  - Marketplace (1): The Cage warning image
  - All ImagePlaceholder components replaced with real `<img>` tags
  - Deployed to kitticker.com/guides
- [x] **pSEO Content Strategy (Session 9):**
  - 4 Brand Authentication Guides (Nike, Adidas, Puma, Umbro)
  - 2 Educational Guides (Kit Types, Marketplace Safety)
  - FAQ Sections with Schema.org FAQPage markup
  - Product Code Checker widget (interactive)
  - Breadcrumb Navigation with BreadcrumbList Schema
  - Related Guides (hub-and-spoke internal linking)
  - CW1526 trending fake code warning
  - Umbro "Dots Test" vintage authentication
  - All deployed to kitticker.com/guides
- [x] **Analytics Setup (Session 8):**
  - GA4 property created: `KitTicker Website`
  - Measurement ID: `G-NQLYJL9D7F`
  - Tracking script added to `BaseLayout.astro`
  - Deployed and verified working
- [x] **SEO & Analytics Setup (Session 7):**
  - Google Search Console verified (DNS TXT)
  - Sitemap `sitemap-index.xml` submitted (6 pages)
  - OG image deployed to `/og-image.png`
  - robots.txt fixed for correct sitemap URL
  - Added `@astrojs/sitemap` integration
- [x] **Domain Deployment (Session 6):**
  - **LIVE:** `https://kitticker.com` + `https://www.kitticker.com`
  - DNS configured: A → 76.76.21.21, CNAME www → cname.vercel-dns.com
  - SSL certificate active ✅
  - All pages verified: `/blog`, `/codes`, `/guides`
- [x] Blog Infrastructure with MDX
- [x] Nike Product Code Guide
- [x] Product code database entries
- [x] Strategic report integration
- [x] 4-Phase roadmap defined

## Next Steps (Priority Order)
1. **Schema Test** → Google Rich Results Test validation
2. **PageSpeed** → Run Lighthouse audit
3. **Community** → Reddit karma building, help in LC threads

## Blockers
None currently.

## Quick Commands
| Command | Action |
|---------|--------|
| `cd landing && npm run dev` | Start dev server (localhost:4321) |
| `cd app && npm run dev` | Start app (localhost:3000) |
| `npm run build` | Build for production |
| `vercel deploy` | Deploy to Vercel |

## Key Files
| File | Purpose |
|------|---------|
| `landing/src/pages/index.astro` | Main landing page |
| `landing/src/pages/guides/` | Guide hub and dynamic routes |
| `landing/src/layouts/GuideLayout.astro` | Guide layout with ToC, Breadcrumb, RelatedGuides |
| `landing/src/components/Breadcrumb.astro` | Breadcrumb with BreadcrumbList Schema |
| `landing/src/components/ProductCodeChecker.astro` | Interactive code validator |
| `landing/src/components/GuideFAQ.astro` | FAQ accordion with FAQPage Schema |
| `landing/src/components/RelatedGuides.astro` | 3-card related guides section |
| `landing/src/content/guides/` | MDX guide content (8 guides) |
| `landing/src/components/Header.astro` | Header with mobile hamburger menu |
| `landing/src/styles/global.css` | Landing design tokens + table styles |

## Decision Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-16 | Domain: kitticker.com | Deployed to Vercel with custom domain |
| 2026-01-16 | Porkbun DNS | A record + CNAME for www |
| 2026-01-16 | CTAs → #pricing | App not ready, avoid 404s |
| 2026-01-16 | SVG icons over emojis | UTF-8 encoding issues |
| 2026-01-16 | Pricing = Coming Soon | Set expectations for early access |
| 2026-01-15 | Content-First Strategy | Strategic report: Build trust before tech |
| 2026-01-15 | Explainable AI | Community rejects black box, need evidence |
| 2026-01-15 | 4-Phase Roadmap | Align with market reality, reduce burn |
| 2026-01-17 | Mobile-first UX | Hamburger menu, responsive typography |

## Key Metrics to Track
| Metric | Phase 1 Target | Current |
|--------|----------------|----------|
| Organic traffic | 1,000 visits/month | Tracking |
| Content pieces | 10 guides published | **8 live** |
| Email signups | 200+ | — |
| Schema markup | HowTo, FAQ, Breadcrumb | ✅ All 3 |
