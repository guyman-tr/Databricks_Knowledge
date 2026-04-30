# Trade.CurrencyPriceFeedDifferences

> Log of bid/ask differences between primary and secondary price feeds when they exceed a configurable tolerance. Used for feed health monitoring and alerting on pricing discrepancies.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | None (append-only log) |
| **Partition** | No |
| **Indexes** | 0 (no PK or indexes in DDL) |

---

## 1. Business Meaning

Trade.CurrencyPriceFeedDifferences stores rows whenever the secondary price feed (Trade.CurrencyPriceSecondary, FeedID=2) reports bid or ask values outside the tolerance band calculated from the primary feed (Trade.CurrencyPrice). Trade.CollectCurrencyPriceDifferencesBetweenFeeds compares primary vs secondary, applies a percentage tolerance (default 10%), and INSERTs into this table (or dbo.Syn_CurrencyPriceFeedDifferences → Real.etoro.Trade.CurrencyPriceFeedDifferences) when the secondary price falls outside [LowerLimit, UpperLimit]. Trade.CurrencyPriceDifferencesAlert reads recent rows, groups by InstrumentID, and sends email when fault count exceeds a threshold.

This table exists because multi-feed price validation is critical: if primary and secondary feeds diverge excessively, it may indicate a data issue, stale feed, or connectivity problem. Logging differences enables monitoring and alerting. Data flows: CollectCurrencyPriceDifferencesBetweenFeeds INSERTs; CurrencyPriceDifferencesAlert SELECTs and aggregates; no explicit purging in DDL (likely retention policy or truncate job elsewhere).

---

## 2. Business Logic

### 2.1 Tolerance-Based Difference Detection

**What**: Primary feed provides reference bid/ask. Lower/Upper limits = Primary ± (tolerance %). Secondary feed is compared; if SecondaryBid or SecondaryAsk is outside limits, a row is logged.

**Columns/Parameters Involved**: `PrimaryBid`, `PrimaryAsk`, `CalculatedLowerBidLimit`, `CalculatedUpperBidLimit`, `CalculatedLowerAskLimit`, `CalculatedUpperAskLimit`, `SecondaryBid`, `SecondaryAsk`

**Rules**:
- @DifferenceTolleranceInPercentage (default 10) → LowerFactor = 1 - tolerance/100, UpperFactor = 1 + tolerance/100.
- LowerBid = PrimaryBid * LowerFactor; UpperBid = PrimaryBid * UpperFactor (same for Ask).
- INSERT when (SecondaryBid < LowerBid OR SecondaryBid > UpperBid) AND (SecondaryAsk < LowerAsk OR SecondaryAsk > UpperAsk) — note: procedure uses CPS.Bid for both bid and ask checks in WHERE (possible typo: one may be CPS.Ask).

### 2.2 Alert on Instrument Fault Count

**What**: CurrencyPriceDifferencesAlert groups by InstrumentID for rows with CollectionTime >= now - 2 minutes. If any instrument has count > @FaultCountBeforeAlert, email is sent with instrument list.

**Columns/Parameters Involved**: `InstrumentID`, `CollectionTime`

**Rules**:
- DEFAULT getdate() on CollectionTime.
- Alert delayed if DBA_ExposureBreakDown_Alert.DelayUntil > getutcdate().

### 2.3 Tradable Instruments Only

**What**: CollectCurrencyPriceDifferencesBetweenFeeds only considers instruments that are enabled on ProviderToInstrument and Tradable=1 in InstrumentMetaData.

---

## 3. Data Overview

| InstrumentID | PrimaryBid | SecondaryBid | PrimaryAsk | SecondaryAsk | PrimaryOccurred | SecondaryOccurred | CollectionTime | Meaning |
|--------------|------------|--------------|------------|---------------|-----------------|-------------------|----------------|---------|
| (No live data sampled) | - | - | - | - | - | - | - | Log table; MCP returned empty. Populated when CollectCurrencyPriceDifferencesBetweenFeeds detects feed divergence. |

**Selection criteria**: Data appears when primary vs secondary feed differences exceed tolerance. Structure and usage from DDL and CollectCurrencyPriceDifferencesBetweenFeeds, CurrencyPriceDifferencesAlert.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | YES | - | CODE-BACKED | Instrument with divergent feed. Implicit FK to Trade.Instrument. |
| 2 | PrimaryBid | dbo.dtPrice | YES | - | CODE-BACKED | Primary feed bid used for comparison. |
| 3 | CalculatedLowerBidLimit | dbo.dtPrice | YES | - | CODE-BACKED | PrimaryBid * (1 - tolerance/100). |
| 4 | CalculatedUpperBidLimit | dbo.dtPrice | YES | - | CODE-BACKED | PrimaryBid * (1 + tolerance/100). |
| 5 | SecondaryBid | dbo.dtPrice | YES | - | CODE-BACKED | Secondary feed bid that exceeded limits. |
| 6 | PrimaryAsk | dbo.dtPrice | YES | - | CODE-BACKED | Primary feed ask used for comparison. |
| 7 | CalculatedLowerAskLimit | dbo.dtPrice | YES | - | CODE-BACKED | PrimaryAsk * (1 - tolerance/100). |
| 8 | CalculatedUpperAskLimit | dbo.dtPrice | YES | - | CODE-BACKED | PrimaryAsk * (1 + tolerance/100). |
| 9 | SecondaryAsk | dbo.dtPrice | YES | - | CODE-BACKED | Secondary feed ask that exceeded limits. |
| 10 | PrimaryOccurred | datetime | YES | - | CODE-BACKED | When primary price was last updated. |
| 11 | SecondaryOccurred | datetime | YES | - | CODE-BACKED | When secondary price was last updated. |
| 12 | CollectionTime | datetime | YES | getdate() | CODE-BACKED | When the difference row was logged. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | Instrument lookup. |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CollectCurrencyPriceDifferencesBetweenFeeds | INSERT (via Syn_CurrencyPriceFeedDifferences) | Writer | Logs feed differences. |
| Trade.CurrencyPriceDifferencesAlert | FROM | Reader | Groups by InstrumentID for alert thresholds. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CurrencyPriceFeedDifferences (table)
└── Trade.Instrument (implicit, via InstrumentID)
     └── Trade.CurrencyPrice (primary feed)
     └── Trade.CurrencyPriceSecondary (secondary feed)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | Implicit InstrumentID lookup |
| Trade.CurrencyPrice | Table | Primary feed source (CollectCurrencyPriceDifferencesBetweenFeeds) |
| Trade.CurrencyPriceSecondary | Table | Secondary feed source (FeedID=2) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CollectCurrencyPriceDifferencesBetweenFeeds | Procedure | INSERT via dbo.Syn_CurrencyPriceFeedDifferences |
| Trade.CurrencyPriceDifferencesAlert | Procedure | SELECT for alert logic |
| dbo.Syn_CurrencyPriceFeedDifferences | Synonym | Points to Real.etoro.Trade.CurrencyPriceFeedDifferences |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (None) | - | - | - | - | No indexes in DDL |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|----------------------|
| DF_Trade_CurrencyPriceFeedDifferences_CollectionTime | DEFAULT | CollectionTime = getdate() |

---

## 8. Sample Queries

### 8.1 Recent differences by instrument
```sql
SELECT InstrumentID, PrimaryBid, SecondaryBid, PrimaryAsk, SecondaryAsk, CollectionTime
  FROM Trade.CurrencyPriceFeedDifferences WITH (NOLOCK)
 WHERE CollectionTime >= DATEADD(MINUTE, -30, GETDATE())
 ORDER BY CollectionTime DESC
```

### 8.2 Instrument fault count (alert logic)
```sql
SELECT InstrumentID, COUNT(*) AS FaultCount
  FROM Trade.CurrencyPriceFeedDifferences WITH (NOLOCK)
 WHERE CollectionTime >= DATEADD(MINUTE, -2, GETDATE())
 GROUP BY InstrumentID
 HAVING COUNT(*) > 5
```

### 8.3 Join with instrument metadata
```sql
SELECT CFD.InstrumentID, IMD.SymbolFull, CFD.PrimaryBid, CFD.SecondaryBid,
       CFD.PrimaryAsk, CFD.SecondaryAsk, CFD.CollectionTime
  FROM Trade.CurrencyPriceFeedDifferences CFD WITH (NOLOCK)
  LEFT JOIN Trade.InstrumentMetaData IMD WITH (NOLOCK)
    ON IMD.InstrumentID = CFD.InstrumentID
 WHERE CFD.CollectionTime >= DATEADD(HOUR, -1, GETDATE())
 ORDER BY CFD.CollectionTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: SSDT DDL, Trade.CollectCurrencyPriceDifferencesBetweenFeeds, Trade.CurrencyPriceDifferencesAlert | Procedures: 2 | Corrections: 0 applied*
*Object: Trade.CurrencyPriceFeedDifferences | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.CurrencyPriceFeedDifferences.sql*
