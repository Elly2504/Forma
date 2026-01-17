# KitTicker - Product Context

## The Problem

### Pain Point 1: No Condition-Adjusted Pricing
eBay "sold" listings show a 1996 Manchester United shirt sold for £50-£400. The range is useless because it doesn't account for:
- Fabric wear (pilling, thinning)
- Print condition (cracks, fading)
- Collar/cuff condition
- Label integrity
- Overall authenticity

### Pain Point 2: Sellers Misprice
Collectors either:
- **Underprice** → Leave money on table (shirt worth £200 sold for £80)
- **Overprice** → No sales, wasted time

### Pain Point 3: Buyers Can't Verify
Sellers claim "near mint" but photos don't show the collar wear or print cracks. No standardized grading system exists.

## The Solution

**KitTicker**: Upload 4 photos → AI analyzes condition → Get adjusted valuation with confidence range.

### User Flow
```
1. User uploads 4 photos (front, back, label, detail)
2. AI Vision analyzes on 6+ criteria:
   - Fabric quality (1-10)
   - Print condition (1-10)
   - Collar/cuff wear (1-10)
   - Label authenticity
   - Overall grade (A+ to F)
3. System cross-references with market data
4. Output: "£185-£220 based on A- condition"
5. Optional: Generate shareable PDF certificate
```

## The Trust Gap (Critical)

> **Core Insight:** In a trust-based market, one bad verdict creates more noise than 100 correct ones.

| Challenge | Solution |
|-----------|----------|
| Collectors reject "black box" AI | **Explainable AI** — Show evidence, not just verdict |
| Human experts provide nuance | Tool must behave like "forensic scientist" |
| 1 false positive = community rejection | Start with Product Code (high accuracy) |

**Output Philosophy:**
```
❌ Bad: "98% Authentic"
✅ Good: "Internal tag code matches Adidas DB for 2022 Real Madrid Away Kit.
         Logo stitching density: 12.4/cm (reference: 12-13/cm)"
```

## Market Segmentation

| Segment | Description | Tech Tolerance | Priority |
|---------|-------------|----------------|----------|
| **Purist Collectors** | Own 10-50+ shirts, deep knowledge | Zero error tolerance | High (gatekeepers) |
| **Blokecore Fashion** | TikTok trend, aesthetic focus | Want fast binary answers | Volume opportunity |
| **Resellers** | Buy/sell on eBay, Depop | Need accurate pricing | Revenue drivers |

> **Strategy:** Win Purist trust first → They validate for Fashion segment.

## Competitive Landscape

| Competitor | Model | Gap / Lesson |
|------------|-------|--------------|
| **KitLegit** | AI Wrapper | Authentication only, no valuation; early Reddit backlash |
| **Legit Check By Ch** | Human-Hybrid + Content | 1M+ words content = SEO moat; THIS IS THE PATH |
| **CollX/Ludex** | Scanner | Works for cards; shirts are too variable |
| **CheckCheck** | Credit System | Per-scan pricing aligns cost with revenue |
| **Terapeak** | eBay analytics | No condition analysis, generic data |
| **Facebook groups** | Crowdsourced | Inconsistent, slow, biased |

**Key Lesson:** Content-first, tech-second. Build authority before asking for money.

## Why Now?
- GPT-4o Vision API is affordable enough for consumer use
- Vintage football shirt market exploding (£2B+ annually)
- No incumbent has solved condition + valuation together
- "Blokecore" trend driving new collectors

## Valuation Data Strategy

| Type | Use | Warning |
|------|-----|---------|
| **Sold Listings** | Primary valuation source | Must separate from Active |
| **Active Listings** | Market sentiment only | Creates unrealistic expectations |

> **Critical:** Never show "Listed Price" as value. Only "Sold Price" = real market value.

## Churn Risk & Mitigation
| Risk | Impact | Mitigation |
|------|--------|------------|
| One-time use | High | Collection tracking, price alerts |
| AI accuracy skepticism | High | Show evidence, allow feedback |
| Free tier abuse | Low | 3/mo limit, watermarks, no certificates |
| Competitor copying | Medium | Network effects, historical data moat |
| False positives | Critical | Start with Product Code verification |
