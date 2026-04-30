# Trade.GetClosingPrice

> Inline table-valued function that returns the most recent closing bid price for an instrument from dbo.HistoryClosingPrices, used for end-of-day valuations and price lookups.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline TVF |
| **Key Identifier** | Returns TABLE with single column ClosingPrice (Bid) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetClosingPrice is a minimal inline table-valued function that returns the latest closing bid price for a given instrument from dbo.HistoryClosingPrices. It selects the single most recent row by TradeDate (TOP 1 ORDER BY TradeDate DESC) and exposes the Bid column as ClosingPrice. This is used for end-of-day valuations, PnL snapshots, and any process that needs the last known closing price when live prices are not available.

This function exists because many reporting and reconciliation flows need a stable closing price reference. dbo.HistoryClosingPrices is populated by the price subsystem with historical closing bids per instrument and trade date. The inline TVF pattern allows CROSS APPLY usage in queries.

Data flows: Called by Trade.Elad111 (OUTER APPLY). Reads from dbo.HistoryClosingPrices. dbo.HistoryClosingPrices is a synonym; actual table may reside in Price or History schema.

---

## 2. Business Logic

### 2.1 Most Recent Closing Bid

**What**: Returns the single most recent closing bid by trade date.

**Columns/Parameters Involved**: `@InstrumentID`, `Bid`, `TradeDate`

**Rules**:
- Filters WHERE InstrumentID = @InstrumentID
- Orders by TradeDate DESC
- Returns TOP 1 row
- Output column: Bid AS ClosingPrice
- Returns empty row set if no history exists for the instrument

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | int | NO | - | CODE-BACKED | Tradable instrument ID. Filters dbo.HistoryClosingPrices to this instrument. |
| 2 | ClosingPrice | decimal | YES | - | CODE-BACKED | Most recent closing bid price. Sourced from Bid column; NULL if no rows for instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | dbo.HistoryClosingPrices | SELECT | Filters and orders by InstrumentID, TradeDate |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.Elad111 | OUTER APPLY | Reader | Gets closing price for instrument in report/analysis |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetClosingPrice (inline TVF)
└── dbo.HistoryClosingPrices (synonym/table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.HistoryClosingPrices | Synonym/Table | FROM — Bid, InstrumentID, TradeDate |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.Elad111 | Procedure | OUTER APPLY Trade.GetClosingPrice(INS.InstrumentID) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get closing price for an instrument
```sql
SELECT ClosingPrice FROM Trade.GetClosingPrice(1);
```

### 8.2 CROSS APPLY closing prices for multiple instruments
```sql
SELECT I.InstrumentID, I.Abbreviation, CP.ClosingPrice
FROM Trade.Instrument I WITH (NOLOCK)
CROSS APPLY Trade.GetClosingPrice(I.InstrumentID) CP
WHERE I.InstrumentID IN (1, 2, 5, 100000);
```

### 8.3 OUTER APPLY to handle instruments with no closing price
```sql
SELECT INS.InstrumentID, INS.Abbreviation,
       ISNULL(CP.ClosingPrice, 0) AS ClosingPrice
FROM Trade.Instrument INS WITH (NOLOCK)
OUTER APPLY Trade.GetClosingPrice(INS.InstrumentID) CP
WHERE INS.InstrumentID <= 10;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 9/10, Logic: 6/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetClosingPrice | Type: Inline TVF | Source: etoro/etoro/Trade/Functions/Trade.GetClosingPrice.sql*
