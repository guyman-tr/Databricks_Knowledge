# Hedge.GetNetting

> Returns all open net hedge positions for a specific liquidity account, providing the hedge server with the current aggregate position state (instrument, size, direction, average rate, value date) for reconciliation and exposure monitoring.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LiquidityAccountID - filters to one LP account's open book |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetNetting` is the hedge server's primary reader for the current open hedge book. Each row returned represents one net aggregate position the hedge server currently holds with a specific liquidity provider account: what instrument is hedged, how many units, in which direction (long/short), at what average entry rate, and with what value date.

This procedure exists because the hedge server needs to know its current hedge book state on startup, after recovery, or when reconciling with the LP. Without it, the server could not determine whether it needs to add or reduce hedge exposure when new customer trades arrive. The procedure wraps the entire Hedge.Netting read path in a TRY/CATCH block with THROW - any error (e.g., if the Netting table is temporarily locked or the FK target is missing) propagates cleanly to the caller rather than silently returning empty results.

Data flows as follows: after a hedge execution (via Hedge.AddOrUpdateNetting), the netting positions change; the hedge server may call GetNetting to refresh its in-memory book view. During server startup or failover recovery, GetNetting loads the current state from the persistent Netting table into the server's working memory. The system-versioned Netting table ensures this data is always current and consistent.

---

## 2. Business Logic

### 2.1 Single-Account Book Read with Error Propagation

**What**: Returns all columns needed for the hedge server to reconstruct its in-memory position book for one LP account.

**Columns/Parameters Involved**: `@LiquidityAccountID`, `InstrumentID`, `Units`, `IsBuy`, `AvgRate`, `ValueDate`

**Rules**:
- WHERE clause: `LiquidityAccountID = @LiquidityAccountID` - all positions for one LP account
- No StatusID, date range, or active-only filter - returns ALL rows for the account (including any zero-unit rows if they exist)
- TRY/CATCH with THROW: errors are re-raised to the caller rather than handled internally
- No ordering specified - caller receives rows in clustered index order (LiquidityAccountID, InstrumentID, ValueDate)
- The caller rebuilds an in-memory dictionary keyed by InstrumentID from the returned rows

**Diagram**:
```
Hedge server startup or recovery:
  GetNetting(@LiquidityAccountID=10)
       |
       v
  Returns: {InstrumentID=1: Units=224M long AvgRate=1.087 ValueDate=2026-02-09}
           {InstrumentID=5: Units=50M long AvgRate=159.32 ValueDate=2026-02-09}
           ...
       |
       v
  Server loads into memory: hedge_book[InstrumentID] = (units, isBuy, avgRate)
  Used for exposure calculation and order sizing
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LiquidityAccountID | int | NO | - | VERIFIED | The LP account whose netting positions to retrieve. Corresponds to Hedge.Netting.LiquidityAccountID and Trade.LiquidityAccounts.LiquidityAccountID. In production, LiquidityAccountID=10 is the primary account. Pass the specific account ID for which the hedge server instance is responsible. |

**Output columns** (from Hedge.Netting - see [Hedge.Netting](../Tables/Hedge.Netting.md) for full column descriptions):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | InstrumentID | int | NO | - | VERIFIED | eToro instrument identifier. Each row represents one instrument's net aggregate position. FK to Trade.Instrument. |
| 3 | Units | decimal(16,2) | YES | - | VERIFIED | Net aggregate position size in eToro units. The total volume the hedge server holds for this instrument on this LP account. Used with IsBuy to represent the full directional exposure. |
| 4 | IsBuy | bit | NO | - | VERIFIED | Direction of the net hedge position. 1=Long (hedge server net bought units on LP), 0=Short (hedge server net sold). Determines PnL sign: long profits when price rises, short profits when price falls. |
| 5 | AvgRate | dbo.dtPrice | YES | - | VERIFIED | Volume-weighted average entry price for the current net position. Cost basis used in unrealized PnL calculation: `PnL = Units * (CurrentBid - AvgRate) * direction`. |
| 6 | ValueDate | date | NO | - | CODE-BACKED | Settlement/delivery date with the LP. When the cash or asset transfer for this hedge position occurs. Included in output for reconciliation with LP confirms. |
| 7 | ExecTime | datetime2(7) | YES | - | CODE-BACKED | Timestamp of the last hedge execution contributing to this position (market execution time). |
| 8 | UpdateTime | datetime2(7) | YES | - | CODE-BACKED | Timestamp when this netting row was last written to the DB. Used to detect stale positions in monitoring. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Hedge.Netting | SELECT | Full table read filtered by LiquidityAccountID. Returns the current live hedge book for one LP account. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | - | Caller | Called on startup and after recovery to load the current hedge book into memory |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetNetting (procedure)
└── Hedge.Netting (table)
      ├── Trade.LiquidityAccounts (table) [FK target]
      ├── Trade.Instrument (table) [implicit FK]
      └── Trade.HedgeServer (table) [implicit FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.Netting | Table | SELECTed - source of all returned netting position data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | External | READER - called at startup and recovery to load current hedge positions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Error handling: wrapped in TRY/CATCH with THROW - any SQL error during execution is re-raised to the caller unchanged.

---

## 8. Sample Queries

### 8.1 Get current hedge book for the main LP account
```sql
EXEC [Hedge].[GetNetting] @LiquidityAccountID = 10;
```

### 8.2 Direct query to see full netting details including temporal columns
```sql
SELECT  n.InstrumentID,
        n.Units,
        CASE WHEN n.IsBuy = 1 THEN 'Long' ELSE 'Short' END AS Direction,
        n.AvgRate,
        n.ValueDate,
        n.ExecTime,
        n.UpdateTime
FROM    [Hedge].[Netting] n WITH (NOLOCK)
WHERE   n.LiquidityAccountID = 10
ORDER BY n.InstrumentID;
```

### 8.3 Compute unrealized PnL on the current hedge book
```sql
SELECT  n.InstrumentID,
        n.Units,
        n.AvgRate,
        cp.Bid AS CurrentBid,
        n.Units * (cp.Bid - n.AvgRate)
            * CASE WHEN n.IsBuy = 1 THEN 1 ELSE -1 END AS UnrealizedPnL
FROM    [Hedge].[Netting] n WITH (NOLOCK)
JOIN    [Trade].[CurrencyPrice] cp WITH (NOLOCK) ON n.InstrumentID = cp.InstrumentID
WHERE   n.LiquidityAccountID = 10
ORDER BY ABS(n.Units * (cp.Bid - n.AvgRate)) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetNetting | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetNetting.sql*
