# History.GetNetProfitForDealing

> Scalar function that computes the USD P&L for a single position using Trade.LastWeekPrices - the "Dealing" variant of GetNetProfit with a simpler single-parameter signature, used by Trade.DealingMasterQuery for bulk unrealized zero P&L summation.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Scalar Function |
| **Signature** | `GetNetProfitForDealing(@PositionID bigint) RETURNS MONEY` |
| **Author** | Bonnie (17/11/2021 - changed positionID to bigint) |
| **Purpose** | Per-position P&L using last-week prices - Dealing engine variant |

---

## 1. Business Meaning

`History.GetNetProfitForDealing` computes the net profit in USD for a position using the same pip-based P&L formula as `History.GetNetProfit`, but with two key differences:

1. **No @PriceXML parameter**: Prices come from `Trade.LastWeekPrices` directly (LEFT OUTER JOIN), not from an XML snapshot. This makes the function callable with just a PositionID - suitable for bulk queries where passing XML per-row would be complex.
2. **Uses `History.GetOnePipValueDollarForDealing`** instead of `History.GetOnePipValueDollar` - the LastWeekPrices-based pip value variant.

The primary consumer is `Trade.DealingMasterQuery`, which sums `History.GetNetProfitForDealing(PositionID) + CommissionOnClose` across all positions in History.Position and Trade.Position grouped by HedgeServerID to compute `UnrealizedZero` (the total P&L at zero-pip prices for dealing engine hedging purposes).

See `History.GetNetProfit.md` for the full P&L formula explanation. The formulas are identical; only the price source differs.

---

## 2. Business Logic

### 2.1 P&L Formula (Identical to GetNetProfit)

Same three-step formula as `History.GetNetProfit`:
1. Pip count = `(LastWeekPrices.Bid + SpreadedPipBid/10^Precision - InitForexRate) * 10^Precision` (long)
   OR `(InitForexRate - LastWeekPrices.Ask - SpreadedPipAsk/10^Precision) * 10^Precision` (short)
2. Lot multiplier = LotCountDecimal
3. One-pip value per unit = `History.GetOnePipValueDollarForDealing(...) / (Benchmark / (AmountInUnitsDecimal / LotCount))`

**Price source**: `Trade.LastWeekPrices` LEFT OUTER JOIN on `HPOS.InstrumentID = TCRP.InstrumentID` (no ProviderID filter).

### 2.2 Position Lookup (History + Trade UNION)

Same as `History.GetNetProfit` - UNION of History.Position and Trade.Position WHERE PositionID = @PositionID.

---

## 3. Data Overview

Execution blocked (scalar function EXECUTE permission not granted). Behavior is identical to `History.GetNetProfit` with LastWeekPrices as the source.

---

## 4. Elements

### Parameters

| # | Parameter | Type | Description |
|---|-----------|------|-------------|
| 1 | @PositionID | bigint | The position to compute P&L for. Searched in both History.Position (archived) and Trade.Position (live). |

### Return Value

| Type | Description |
|------|-------------|
| MONEY | USD P&L for the position at last-week prices. Positive = profit, negative = loss. NULL if position not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | History.Position | Query (EtoroArchive) | Archived position data |
| @PositionID | Trade.Position | Query (cross-schema) | Live position data |
| InstrumentID | Trade.LastWeekPrices | LEFT JOIN (cross-schema) | End-of-week prices for pip count calculation |
| InstrumentID + ProviderID | Trade.ProviderToInstrument | Query (cross-schema) | Precision and Benchmark |
| (all) | History.GetOnePipValueDollarForDealing | Function call | One-pip USD value using last-week prices |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| Trade.DealingMasterQuery | Stored Procedure | ACTIVE - sums `History.GetNetProfitForDealing(PositionID) + CommissionOnClose` grouped by HedgeServerID to compute UnrealizedZero for hedge P&L reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetNetProfitForDealing (scalar function)
|--> History.Position (view -> EtoroArchive)
|--> Trade.Position (table, cross-schema)
|--> Trade.LastWeekPrices (table, cross-schema)
|--> Trade.ProviderToInstrument (table, cross-schema)
+--> History.GetOnePipValueDollarForDealing (scalar function)
        |--> Trade.Provider, Trade.Instrument, Dictionary.Currency
        |--> Customer.Customer, Trade.GetSpreadGroup, Trade.ProviderToInstrument
        +--> Trade.LastWeekPrices
```

---

## 7. Technical Details

See `History.GetNetProfit.md` Section 7 for variant comparison and performance warnings. The key advantage of this "ForDealing" variant: the simpler single-parameter signature allows `Trade.DealingMasterQuery` to call it inline in a SELECT SUM() without constructing per-row XML.

---

## 8. Sample Queries

### 8.1 Get P&L for a position using last-week prices

```sql
SELECT History.GetNetProfitForDealing(123456789) AS PositionPnL
```

### 8.2 Pattern used by Trade.DealingMasterQuery

```sql
-- Sum unrealized zero P&L by hedge server (History.Position)
SELECT
    HedgeServerID,
    SUM(History.GetNetProfitForDealing(PositionID) + CommissionOnClose) AS UnrealizedZero
FROM History.Position HP WITH(NOLOCK)
JOIN Customer.Customer CST WITH(NOLOCK) ON HP.CID = CST.CID
GROUP BY HedgeServerID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 8.8/10, Logic: 9.0/10, Relationships: 9.2/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 5, 7, 8, 10, 11) - EtoroArchive blocked*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 direct consumer | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetNetProfitForDealing | Type: Scalar Function | Source: etoro/etoro/History/Functions/History.GetNetProfitForDealing.sql*
