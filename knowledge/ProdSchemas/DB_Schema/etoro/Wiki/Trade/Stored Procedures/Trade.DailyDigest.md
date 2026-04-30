# Trade.DailyDigest

> Generates a daily trading activity digest for US users engaged in CopyTrader, aggregating buy and sell trade counts by customer, mirror relationship, and instrument type within a specified time window.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns aggregated result set |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DailyDigest generates a daily summary of trading activity specifically for US users who are participating in CopyTrader (mirror trading). For each user copying another trader, it counts how many positions were opened (buys) and closed (sells) during a time window, broken down by instrument type (Stocks and ETF grouped together, other types separate).

This report is likely driven by US regulatory requirements for copy-trading activity reporting. The SEC and FINRA have specific disclosure requirements around managed/copied accounts, and this digest provides the raw data for compliance reports or user-facing daily trade summaries showing what their copied trader did.

The procedure searches both active positions (Trade.PositionTbl) and closed positions (History.PositionSlim) to capture the complete picture: positions opened today that are still open, positions opened today that were already closed, and positions that existed before but were closed today. It filters to only US users via Trade.IsUsUser and only mirror-based trades (MirrorID <> 0).

---

## 2. Business Logic

### 2.1 Three-Source Trade Counting

**What**: Trade counts are aggregated from three separate queries combined via UNION ALL to capture all trading activity in the time window.

**Columns/Parameters Involved**: `@startTime`, `@endTime`, `Trade.PositionTbl`, `History.PositionSlim`

**Rules**:
- Source 1: Positions opened in the window that are still open (PositionTbl, InitDateTime in range, StatusID=1) -> counted as buys
- Source 2: Positions closed in the window (History.PositionSlim, CloseOccurred in range) -> counted as sells
- Source 3: Positions opened in the window but already closed (History.PositionSlim, InitDateTime in range) -> counted as buys
- All three filter: MirrorID <> 0 (copy-trade only) AND IsUsUser = 1 (US users only)
- Optional @mirrorIds filter narrows to specific mirror relationships

### 2.2 Instrument Type Grouping

**What**: Stocks and ETFs are grouped together; other instrument types remain separate.

**Columns/Parameters Involved**: `InstrumentMetaData.InstrumentTypeID`, `Dictionary.CurrencyType`

**Rules**:
- CASE WHEN InstrumentType IN ('Stocks', 'ETF') THEN 'Stocks and ETF' ELSE InstrumentType
- Groups: "Stocks and ETF", "Crypto", "Currencies", etc.

**Diagram**:
```
Time Window [@startTime, @endTime)
    |
    +-- PositionTbl (open positions initiated in window, StatusID=1)
    |     -> IsOpenPosition = 1 (Buy counter)
    |
    +-- PositionSlim (closed in window)
    |     -> IsOpenPosition = 0 (Sell counter)
    |
    +-- PositionSlim (opened in window, already closed)
          -> IsOpenPosition = 1 (Buy counter)
    |
    +-- UNION ALL -> GROUP BY GCID, MirrorID, InstrumentType, IsOpenPosition
    |
    +-- JOIN Mirror for ParentCID/ParentUserName
    |
    +-- Final result: per-user, per-copied-trader, per-instrument-type buy/sell counts
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @startTime | DATETIME | NO | - | CODE-BACKED | Start of the reporting window (inclusive). Typically midnight UTC for daily digests. |
| 2 | @endTime | DATETIME | NO | - | CODE-BACKED | End of the reporting window (exclusive). Typically midnight UTC of the next day. |
| 3 | @mirrorIds | Trade.IdIntList (TVP) | NO | - | CODE-BACKED | Optional filter for specific mirror relationship IDs. If empty, all mirror IDs are included. If populated, only trades for these specific copy-trade relationships are counted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Open positions | Trade.PositionTbl | Reader | Reads active positions opened in the time window |
| Closed positions | History.PositionSlim | Reader | Reads closed positions for both buy and sell counting |
| Customer data | Customer.Customer | Lookup | Joins for GCID and UserName resolution |
| US check | Trade.IsUsUser | Function | CROSS APPLY to filter only US-regulated users |
| Instrument type | Trade.InstrumentMetaData | Lookup | Resolves InstrumentID to InstrumentTypeID |
| Type name | Dictionary.CurrencyType | Lookup | Resolves InstrumentTypeID to display name (Stocks, ETF, Crypto, etc.) |
| Mirror data | Trade.Mirror | Lookup | Resolves MirrorID to ParentCID and ParentUserName (the copied trader) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application layer | Scheduled call | Consumer | Called daily (or on demand) for US CopyTrader activity reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DailyDigest (procedure)
+-- Trade.PositionTbl (table)
+-- History.PositionSlim (table)
+-- Customer.Customer (table)
+-- Trade.IsUsUser (function)
+-- Trade.InstrumentMetaData (table)
+-- Dictionary.CurrencyType (table)
+-- Trade.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Active positions - opened-in-window buys |
| History.PositionSlim | Table | Closed positions - sells and already-closed buys |
| Customer.Customer | Table | GCID and UserName resolution |
| Trade.IsUsUser | Table-Valued Function | Filters to US-regulated users only |
| Trade.InstrumentMetaData | Table | InstrumentID to InstrumentTypeID mapping |
| Dictionary.CurrencyType | Table | InstrumentTypeID to display name |
| Trade.Mirror | Table | MirrorID to ParentCID/ParentUserName |
| Trade.IdIntList | User Defined Type | TVP for optional mirror ID filter |

### 6.2 Objects That Depend On This

No dependents found. Called from the application layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

Uses OPTION(RECOMPILE) hint to force fresh plan generation on each execution, ensuring optimal plan for the given @startTime/@endTime range and @mirrorIds cardinality.

---

## 8. Sample Queries

### 8.1 Check US users with active mirror positions
```sql
SELECT DISTINCT pt.CID, c.GCID, c.UserName, pt.MirrorID
FROM   Trade.PositionTbl pt WITH (NOLOCK)
       JOIN Customer.Customer c WITH (NOLOCK) ON c.CID = pt.CID
       CROSS APPLY Trade.IsUsUser(pt.CID) IsUs
WHERE  pt.MirrorID <> 0
       AND pt.StatusID = 1
       AND IsUs.IsUsUser = 1
```

### 8.2 View mirror relationships
```sql
SELECT MirrorID, ParentCID, ParentUserName
FROM   Trade.Mirror WITH (NOLOCK)
WHERE  MirrorID IN (100, 200, 300)
```

### 8.3 Count trades by instrument type for today
```sql
SELECT imd.InstrumentTypeID, ct.Name, COUNT(*) AS TradeCount
FROM   Trade.PositionTbl pt WITH (NOLOCK)
       JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON imd.InstrumentID = pt.InstrumentID
       JOIN Dictionary.CurrencyType ct WITH (NOLOCK) ON ct.CurrencyTypeID = imd.InstrumentTypeID
WHERE  pt.InitDateTime >= CAST(GETUTCDATE() AS DATE)
GROUP BY imd.InstrumentTypeID, ct.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DailyDigest | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DailyDigest.sql*
