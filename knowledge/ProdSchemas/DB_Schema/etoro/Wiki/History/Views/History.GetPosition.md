# History.GetPosition

> Position view enriched with hedge server data and instrument currency IDs - joins History.Position with a unified hedge source (History.Hedge UNION ALL Trade.Hedge) and Trade.Instrument, converting money values to INTEGER cents. One consumer: BackOffice.GetInstrumentPopularityPerCustomer.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | PositionID (bigint) from History.Position |
| **Partition** | N/A |
| **Indexes** | N/A (view - base table indexes used) |

---

## 1. Business Meaning

History.GetPosition is a legacy enriched position view that combines closed position data with hedge execution details and instrument currency information. It was the primary interface for systems that needed position data enriched with the hedge server context (TradeID, AccountID, HedgeServerID, HedgedLotCountDecimal) for reconciliation with LP (liquidity provider) trading systems.

The view selects 36 columns from History.Position, enriched with:
- Hedge data from a unified (History.Hedge UNION ALL Trade.Hedge) subquery, LEFT joined on HedgeID - providing TradeID, AccountID, HedgeServerID, and LotCountDecimal from the hedge side
- Instrument currency pair (BuyCurrencyID, SellCurrencyID as ForexBuy/ForexSell) from Trade.Instrument

Money values are converted to INTEGER cents: Amount*100, NetProfit*100, Commission*100, CommissionOnClose*100, EndOfWeekFee*100.

The view has **1 consumer** (BackOffice.GetInstrumentPopularityPerCustomer), suggesting it is a legacy view that was more widely used in older platform versions.

---

## 2. Business Logic

### 2.1 Unified Hedge Source (History + Trade)

**What**: Hedge data is sourced from both historical and live hedge tables via UNION ALL.

**Columns/Parameters Involved**: `HedgeID`, `TradeID`, `AccountID`, `HedgeServerID`, `HedgedLotCountDecimal`

**Rules**:
- History.Hedge (WITH NOLOCK): provides Commission as well as the core hedge columns
- Trade.Hedge (WITH NOLOCK): provides the same columns but Commission returned as NULL (the Trade table may not have Commission or it's not needed for live hedges)
- LEFT OUTER JOIN: positions without a hedge record (non-hedged or for which hedge was already archived/deleted) still appear; hedge columns are NULL for such positions

### 2.2 Money to Cents Conversion

**What**: Financial amounts are returned in integer cents rather than decimal dollars.

**Columns/Parameters Involved**: `Amount`, `NetProfit`, `Commission`, `CommissionOnClose`, `EndOfWeekFee`

**Rules**:
- `Amount = CAST(HPOS.Amount*100 AS INTEGER)` - investment in cents
- `NetProfit = CAST(HPOS.NetProfit*100 AS INTEGER)` - profit/loss in cents
- `Commission = CAST(HPOS.Commission*100 AS INTEGER)` - commission in cents
- `CommissionOnClose = CAST(HPOS.CommissionOnClose*100 AS INTEGER)` - close commission in cents
- `EndOfWeekFee = CAST(HPOS.EndOfWeekFee*100 AS INTEGER)` - EOW fee in cents
- Rates (InitForexRate, EndForexRate, LimitRate, StopRate) are returned as DOUBLE PRECISION

### 2.3 Column Selections

**What**: 36 output columns combining position data + hedge data + instrument currencies.

**Rules**:
- Position columns: ForexResultID, PositionID, CID, CurrencyID, ProviderID, GameServerID, HedgeID, HedgeServerID as PositionHedgeServerID, rates/amounts/flags, timing, action metadata
- Hedge columns: HedgeServerID (from hedge side), TradeID, AccountID, HedgedLotCountDecimal
- Instrument: ForexBuy (BuyCurrencyID), ForexSell (SellCurrencyID)
- OpenOccurred aliased as Occurred

---

## 3. Data Overview

Same underlying data as History.Position (full history across all UNION ALL branches). The hedge data enrichment may return NULL for positions where hedge records are not available (older positions, non-hedged instruments).

---

## 4. Elements

36 columns - see History.Position.md for base position column descriptions. Key differences:

| Element | Notes |
|---------|-------|
| Amount | CAST(Amount*100 AS INTEGER) - cents |
| NetProfit | CAST(NetProfit*100 AS INTEGER) - cents |
| Commission | CAST(Commission*100 AS INTEGER) - cents |
| InitForexRate | CAST AS DOUBLE PRECISION |
| EndForexRate | CAST AS DOUBLE PRECISION |
| LimitRate | CAST AS DOUBLE PRECISION |
| StopRate | CAST AS DOUBLE PRECISION |
| PositionHedgeServerID | HPOS.HedgeServerID - from position's own hedge server reference |
| HedgeServerID | HHDG.HedgeServerID - from the joined hedge record |
| HedgedLotCountDecimal | From History.Hedge / Trade.Hedge - hedge-side lot count |
| TradeID | From History.Hedge / Trade.Hedge - LP trade identifier |
| AccountID | From History.Hedge / Trade.Hedge - LP account identifier |
| ForexBuy | Trade.Instrument.BuyCurrencyID |
| ForexSell | Trade.Instrument.SellCurrencyID |
| Occurred | HPOS.OpenOccurred (aliased) |
| OrderID | ISNULL(OrderID, 0) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (base) | History.Position | View (source) | All closed positions |
| HedgeID | History.Hedge | LEFT JOIN (UNION ALL) | Historical hedge records |
| HedgeID | Trade.Hedge | LEFT JOIN (UNION ALL) | Live hedge records |
| InstrumentID | Trade.Instrument | INNER JOIN (implicit WHERE) | Instrument currency IDs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetInstrumentPopularityPerCustomer | PositionID/InstrumentID | Read | Instrument popularity analysis per customer |

---

## 6. Dependencies

```
History.GetPosition (view)
|- History.Position (view - full position history)
|- History.Hedge (table - historical hedge records)
|- Trade.Hedge (table - live hedge records)
+- Trade.Instrument (table - instrument currency IDs)
```

---

## 7. Technical Details

No special indexes. The implicit WHERE `HPOS.InstrumentID = TISR.InstrumentID` is an INNER JOIN using comma syntax (ANSI-89 style). All positions have a valid InstrumentID so no rows are lost.

---

## 8. Sample Queries

### 8.1 Get hedge-enriched position data for a customer
```sql
SELECT
    gp.PositionID,
    gp.ForexBuy,
    gp.ForexSell,
    gp.Amount,
    gp.NetProfit,
    gp.TradeID,
    gp.HedgeServerID
FROM History.GetPosition gp WITH (NOLOCK)
WHERE gp.CID = 14952810
ORDER BY gp.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for History.GetPosition.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 8.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 36 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 consumer found | App Code: 0 repos | Corrections: 0 applied*
*Object: History.GetPosition | Type: View | Source: etoro/etoro/History/Views/History.GetPosition.sql*
