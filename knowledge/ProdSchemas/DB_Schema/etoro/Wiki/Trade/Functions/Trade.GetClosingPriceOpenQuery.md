# Trade.GetClosingPriceOpenQuery

> Inline table-valued function that returns the most recent closing bid price for an instrument via OPENQUERY to a linked server (AO-PRICE-LSN-ROR), used when local dbo.HistoryClosingPrices is not the source of truth.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline TVF |
| **Key Identifier** | Returns TABLE with single column ClosingPrice (Bid) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetClosingPriceOpenQuery is a variant of Trade.GetClosingPrice that fetches the closing bid from a remote database via OPENQUERY. It queries `[AO-PRICE-LSN-ROR].[Price].[History].[ClosingPrices]` for the given InstrumentID and returns the most recent row by TradeDate. The output is identical to Trade.GetClosingPrice (Bid AS ClosingPrice) but the data source is the linked server, not local dbo.HistoryClosingPrices.

This function exists because some environments or reporting flows need to pull closing prices from a specific price database (e.g., read replica, centralized price store) rather than the local synonym. OPENQUERY pushes the filter to the remote server. Requires the linked server [AO-PRICE-LSN-ROR] to be configured.

Data flows: Read-only. No callers found in this phase. Used when local HistoryClosingPrices is not populated or when a different price source is required.

---

## 2. Business Logic

### 2.1 Most Recent Closing Bid via OPENQUERY

**What**: Returns the single most recent closing bid from remote Price.History.ClosingPrices.

**Columns/Parameters Involved**: `@InstrumentID`, `Bid`, `InstrumentID`, `TradeDate`

**Rules**:
- OPENQUERY fetches Bid, InstrumentID, TradeDate from remote Price.History.ClosingPrices
- Local WHERE filters CP.InstrumentID = @InstrumentID
- ORDER BY TradeDate DESC, TOP 1
- Output: Bid AS ClosingPrice
- Returns empty row set if linked server has no rows for the instrument or if linked server is unavailable

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | int | NO | - | CODE-BACKED | Tradable instrument ID. Filters remote ClosingPrices to this instrument. |
| 2 | ClosingPrice | decimal | YES | - | CODE-BACKED | Most recent closing bid from remote. Sourced from Bid; NULL if no rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | [AO-PRICE-LSN-ROR].Price.History.ClosingPrices | OPENQUERY | Remote table filtered by InstrumentID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetClosingPriceOpenQuery (inline TVF)
└── [AO-PRICE-LSN-ROR].Price.History.ClosingPrices (linked server table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Linked Server AO-PRICE-LSN-ROR | External | OPENQUERY — Price.History.ClosingPrices |
| Price.History.ClosingPrices | Table (remote) | Bid, InstrumentID, TradeDate |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get closing price from linked server
```sql
SELECT ClosingPrice FROM Trade.GetClosingPriceOpenQuery(1);
```

### 8.2 CROSS APPLY for multiple instruments (requires linked server)
```sql
SELECT I.InstrumentID, I.Abbreviation, CP.ClosingPrice
FROM Trade.Instrument I WITH (NOLOCK)
CROSS APPLY Trade.GetClosingPriceOpenQuery(I.InstrumentID) CP
WHERE I.InstrumentID IN (1, 2, 5);
```

### 8.3 Compare local vs linked server closing prices
```sql
SELECT L.InstrumentID,
       L.ClosingPrice AS LocalClosingPrice,
       R.ClosingPrice AS RemoteClosingPrice
FROM Trade.GetClosingPrice(1) L
FULL OUTER JOIN Trade.GetClosingPriceOpenQuery(1) R ON 1=1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.8/10 (Elements: 9/10, Logic: 6/10, Relationships: 6/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetClosingPriceOpenQuery | Type: Inline TVF | Source: etoro/etoro/Trade/Functions/Trade.GetClosingPriceOpenQuery.sql*
