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

## Competitive Landscape

| Competitor | What They Do | Gap |
|------------|--------------|-----|
| **KitLegit** | Authentication only | No valuation, no condition grading |
| **Terapeak** | eBay analytics | No condition analysis, generic data |
| **Price guides** | Static PDFs | Outdated, no condition adjustment |
| **Facebook groups** | Crowdsourced opinions | Inconsistent, slow, biased |

## Why Now?
- GPT-4o Vision API is affordable enough for consumer use
- Vintage football shirt market exploding (£2B+ annually)
- No incumbent has solved condition + valuation together

## Revenue Projections
| Milestone | Signups | Conversion | Paying Users | Est. MRR |
|-----------|---------|------------|--------------|----------|
| Week 2 | 200 | 10% | 20 | $100-150 |
| Month 1 | 500 | 12% | 60 | $400-500 |
| Month 3 | 1,500 | 15% | 225 | $1,500+ |

**Breakdown assumption:** 70% Free, 25% Collector ($9.99), 5% Dealer ($49.99)

## Churn Risk & Mitigation
| Risk | Impact | Mitigation |
|------|--------|------------|
| One-time use (get valuation, leave) | High | Collection tracking, price alerts |
| AI accuracy skepticism | Medium | Show confidence scores, allow feedback |
| Free tier abuse | Low | 3/mo limit, watermarks, no certificates |
| Competitor copying | Medium | Network effects, historical data moat |
