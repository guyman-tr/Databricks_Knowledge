# History.ClosePositionEndOfDay

> End-of-day PnL enrichment view for recently closed positions - adds a computed EndOfDayPnLInDollars, real-time closing rate from today's prices, and close-fee-on-open estimates to the History.PositionForExternalUse base, filtered to the last 30 days.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | PositionID (int, from History.PositionForExternalUse) |
| **Partition** | N/A (view - filtered to last 30 days for performance) |
| **Indexes** | N/A (view - base table indexes used) |

---

## 1. Business Meaning

`History.ClosePositionEndOfDay` enriches recently closed positions with an end-of-day mark-to-market P&L computation. The view takes the full History.PositionForExternalUse dataset (filtered to the last 30 days) and enriches each row with:

1. **EndOfDayPnLInDollars**: The computed P&L as of today's most recent price snapshot - but only shown if `CloseOccurred > CAST(GETUTCDATE() AS DATE)`, meaning the position closed today (or has a future close date). For positions closed before today, this is NULL.
2. **EstimateCloseFeeOnOpen**: An estimate of the fee that would apply if closing the position at open, computed by `Trade.FnGetCloseFeeOnOpen`.
3. **EstimateCloseFeeOnOpenByUnits**: The same fee estimate expressed per-units.

The view is used for end-of-day risk reporting and position monitoring. The 30-day WHERE filter (`HPOS.CloseOccurred >= getutcdate()-30`) is explicitly documented in the DDL comment: "For performance to avoid going to all the History.Position tables in EtoroArchive".

**Companion view**: `History.ClosePositionEndOfDay_Try` has nearly identical logic but uses inline fee calculation (`Trade.FnGetCloseFeeInPercentage`) instead of `Trade.FnGetCloseFeeOnOpen`.

No stored procedures in the SSDT repo directly reference this view (only a maintenance RefreshViews script). It is likely consumed by external reporting tools or application code.

---

## 2. Business Logic

### 2.1 Price CTE (PriceMaxData)

**What**: Pre-computes today's latest Bid/Ask prices for all instruments.

**Rules**:
- `WITH PriceMaxData AS (SELECT InstrumentID, AskSpreaded, BidSpreaded, Bid, Ask, PriceRateID FROM History.CurrencyPriceMaxDateWithSplitView WHERE Occurred > CAST((GETUTCDATE()-1) AS DATE))`
- Filters to prices from yesterday onwards - i.e., today's prices only
- Referenced twice: once for the instrument's own price (EOD), once for the conversion instrument's price (ConvEd)

### 2.2 EndOfDayPnLInDollars Calculation

**What**: Computes P&L at current market close for positions that closed today.

**Rules**:
- `CASE WHEN HPOS.CloseOccurred > CAST(GETUTCDATE() AS DATE) THEN PnL.PnLInDollars ELSE NULL END`
- Only populated for positions with CloseOccurred after midnight today (same-day closes)
- `PnL.PnLInDollars` comes from `CROSS APPLY Trade.FnCalculatePnLWrapper(...)` which takes position params + current closing rate

### 2.3 Closing Rate Selection

**What**: Selects the appropriate price (Bid/Ask, spreaded or raw) based on position direction and real/synthetic status.

**Rules** (ClosingRateEOD CROSS APPLY):
- IsBuy=1, IsRealPosition=0 (synthetic long): `EOD.BidSpreaded` - closing sells at client-facing bid
- IsBuy=1, IsRealPosition=1 (real long): `EOD.Bid` - closing at raw bid
- IsBuy=0, IsRealPosition=0 (synthetic short): `EOD.AskSpreaded` - closing buys at client-facing ask
- IsBuy=0, IsRealPosition=1 (real short): `EOD.Ask` - closing at raw ask

### 2.4 FX Conversion Rate

**What**: Determines the conversion rate from instrument currency to USD.

**Rules** (ConversionRate CROSS APPLY - 9 cases):
- Uses `Trade.FnGetConversionInstrument(InstrumentID, CurrencyID)` to get ConversionInstrumentID and IsReciprocal flag
- If no conversion needed (ConversionInstrumentID = InstrumentID and IsReciprocal=0): rate = 1
- Otherwise: uses ConvEd Bid/Ask or reciprocal (1/Bid, 1/Ask) based on IsReciprocal flag, position direction, and real/synthetic status

### 2.5 30-Day Performance Filter

**What**: WHERE clause limits to last 30 days to avoid full EtoroArchive scan.

**Rules**:
- `WHERE HPOS.CloseOccurred >= GETUTCDATE()-30`
- Without this filter, History.PositionForExternalUse would scan all 78 archive branches in EtoroArchive
- Means this view only shows positions closed within the rolling 30-day window

---

## 3. Data Overview

Direct query blocked (History.PositionForExternalUse routes to EtoroArchive for position data). Based on business context: last 30 days of closed positions with end-of-day PnL enrichment.

---

## 4. Elements

All base position columns come from `History.PositionForExternalUse` (126 columns - see that document). Plus:

| # | Added Element | Type | Source | Description |
|---|--------------|------|--------|-------------|
| 127 | EndOfDayPnLInDollars | MONEY | Trade.FnCalculatePnLWrapper | Computed P&L in USD at today's closing rate. NULL for positions closed before today. |
| 128 | EstimateCloseFeeOnOpen | MONEY | Trade.FnGetCloseFeeOnOpen | Estimated fee if the position were closed at open. 0 if OpenTotalFees = 0. |
| 129 | EstimateCloseFeeOnOpenByUnits | MONEY | Trade.FnGetCloseFeeOnOpen | Same fee estimate proportioned to current units. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HPOS.* | History.PositionForExternalUse | View base (NOLOCK) | 126-column position view - filtered to last 30 days |
| EOD, ConvEd | History.CurrencyPriceMaxDateWithSplitView | CTE (PriceMaxData) | Today's latest Bid/Ask prices for instruments and conversion instruments |
| Ci | Trade.FnGetConversionInstrument | CROSS APPLY (cross-schema) | Resolves USD conversion instrument for the position's instrument/currency pair |
| PosiEndOfDate | Trade.FnIsRealPosition | CROSS APPLY (cross-schema) | Determines if position is real (stock) or synthetic (CFD) |
| PnL | Trade.FnCalculatePnLWrapper | CROSS APPLY (cross-schema) | Computes actual PnLInDollars at current closing rate |
| CloseFeeOnOpen | Trade.FnGetCloseFeeOnOpen | OUTER APPLY (cross-schema) | Estimates close fee if position closed at open |

### 5.2 Referenced By (other objects point to this)

No active SSDT consumers. Likely consumed by external reporting or application code.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ClosePositionEndOfDay (view, 30-day filter)
|--> History.PositionForExternalUse (view)
|       +--> History.Position + Trade.PositionOpenInDLT
|--> History.CurrencyPriceMaxDateWithSplitView (view - today's prices)
|--> Trade.FnGetConversionInstrument (function)
|--> Trade.FnIsRealPosition (function)
|--> Trade.FnCalculatePnLWrapper (function)
+--> Trade.FnGetCloseFeeOnOpen (function)
```

---

## 7. Technical Details

### 7.1 Performance Characteristics

- The 30-day WHERE clause is critical - without it, the view triggers a full EtoroArchive UNION ALL scan across all 78 History.Position branches.
- Four CROSS APPLY calls per row (FnGetConversionInstrument, FnIsRealPosition, FnCalculatePnLWrapper, FnGetCloseFeeOnOpen) - these are row-level scalar function calls, which can be expensive for large result sets.
- The PriceMaxData CTE is evaluated once and cached; the two LEFT JOINs back to it (EOD and ConvEd) reuse that result.

### 7.2 Differences from ClosePositionEndOfDay_Try

| Aspect | ClosePositionEndOfDay | ClosePositionEndOfDay_Try |
|--------|----------------------|--------------------------|
| Close fee function | `Trade.FnGetCloseFeeOnOpen` (OUTER APPLY) | Inline IIF formula + `Trade.FnGetCloseFeeInPercentage` |
| Logic comment | None on fee calc | "---Missing Columns" note on PnL CROSS APPLY |
| Status | Current production | Experimental ("_Try") - no consumers |

---

## 8. Sample Queries

### 8.1 Get today's closed positions with end-of-day PnL

```sql
SELECT
    cp.PositionID,
    cp.CID,
    cp.InstrumentID,
    cp.IsBuy,
    cp.CloseOccurred,
    cp.EndOfDayPnLInDollars,
    cp.EstimateCloseFeeOnOpen
FROM History.ClosePositionEndOfDay cp WITH(NOLOCK)
WHERE cp.CloseOccurred >= CAST(GETUTCDATE() AS DATE)
ORDER BY cp.CloseOccurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 8.8/10, Logic: 9.2/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 5, 7, 8, 10, 11) - EtoroArchive blocked*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 direct consumers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ClosePositionEndOfDay | Type: View | Source: etoro/etoro/History/Views/History.ClosePositionEndOfDay.sql*
