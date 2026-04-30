# Hedge.AddAccountPositionsInsert

> Populates Hedge.AccountOpenPositions and Hedge.AccountClosedPositions for a given hedge server by aggregating live hedge positions from Trade.Hedge and history from History.Hedge since a given date.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to Hedge.AccountOpenPositions and Hedge.AccountClosedPositions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.AddAccountPositionsInsert` is an initialization/refresh procedure that rebuilds the real-time account position snapshot tables for a specific hedge server. It serves as the inner data population logic called by `Hedge.AddAccountPositions`.

The procedure computes two sets of data:
1. **Open positions** (`Hedge.AccountOpenPositions`): Aggregates currently open hedge positions from `Trade.Hedge` - the live hedge position table - per LiquidityAccount/Instrument combination, computing unrealized P&L via `Internal.GetNetProfitHedgeWithPriceRateID` and net open USD via `Internal.GetNetOpenInUSD`.
2. **Closed positions** (`Hedge.AccountClosedPositions`): Aggregates realized P&L from both `History.Hedge` (positions closed after `@FromDate`) and `Trade.Hedge` (positions opened after `@FromDate`) - capturing a window of recent activity.

This procedure is typically called when a hedge server starts up or recovers, to reseed its position tables from the authoritative source-of-truth tables.

---

## 2. Business Logic

### 2.1 Open Position Reconstruction from Trade.Hedge

**What**: Recalculates current open hedge positions from the live hedge position table.

**Columns/Parameters Involved**: `@HedgeServerID`, `@FromDate`

**Rules**:
- Queries `Trade.Hedge` with `NOLOCK` for all positions where `HedgeServerID = @HedgeServerID` and `LiquidityAccountID IS NOT NULL` (excludes unrouted positions).
- Groups by `HedgeServerID`, `LiquidityAccountID`, `InstrumentID`.
- Unrealized P&L computed via `Internal.GetNetProfitHedgeWithPriceRateID(TH.HedgeID)` - cross-applies current market rates.
- Net open USD computed via `Internal.GetNetOpenInUSD(InstrumentID, LotCountDecimal)`.
- Result INSERTed into `Hedge.AccountOpenPositions`.

### 2.2 Closed Position Window from History + Trade

**What**: Builds the closed position P&L for the period since @FromDate by combining historical and still-open recent positions.

**Columns/Parameters Involved**: `@HedgeServerID`, `@FromDate`

**Rules**:
- UNION ALL of two sources:
  - `History.Hedge` with IX_History_Hedge_CloseOccurred index hint: positions that closed after `@FromDate`. `NetProfit` used directly.
  - `Trade.Hedge` for positions where `Occurred > @FromDate` (recently opened): contributes `0` net profit (no realized P&L yet) but `0` execution volume (commented-out calculation).
- ExecutionVolumeInUSD is set to `0` in both branches (commented-out calculation - the volume calculation via `GetNetOpenInUSD` was disabled by the developer per inline comment).
- Grouped by `HedgeServerID`, `LiquidityAccountID`, `InstrumentID` with `SUM(NetProfit)` and `SUM(ExecutionVolumeInUSD)`.
- Result INSERTed into `Hedge.AccountClosedPositions`.

**Diagram**:
```
@HedgeServerID, @FromDate
  |
  +-- Trade.Hedge (NOLOCK) -------> SUM unrealized PnL -----> INSERT Hedge.AccountOpenPositions
  |   (all open positions)          CROSS APPLY GetNetProfit
  |
  +-- History.Hedge (CloseOccurred > @FromDate) -+
  |                                              |-> UNION ALL -> GROUP BY (HS, LA, Inst)
  +-- Trade.Hedge (Occurred > @FromDate) --------+              -> INSERT Hedge.AccountClosedPositions
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | INT | NO | - | CODE-BACKED | The hedge server for which to rebuild account position data. Scopes all queries to this server's positions. Implicit FK to Trade.HedgeServer. |
| 2 | @FromDate | DATETIME | NO | - | CODE-BACKED | Lookback start date for the closed position window. History.Hedge rows with CloseOccurred > @FromDate and Trade.Hedge rows with Occurred > @FromDate are included in the closed positions insert. Typically set to the server's last archive date. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeServerID | Trade.Hedge | JOIN/FILTER | Reads all open hedge positions for this server |
| @HedgeServerID | History.Hedge | JOIN/FILTER | Reads closed hedge positions since @FromDate |
| - | Internal.GetNetProfitHedgeWithPriceRateID | CROSS APPLY | Computes unrealized P&L for each open hedge position |
| - | Internal.GetNetOpenInUSD | Function call | Computes net open USD value for open positions |
| - | Hedge.AccountOpenPositions | INSERT | Writes computed open position aggregates |
| - | Hedge.AccountClosedPositions | INSERT | Writes realized P&L window data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.AddAccountPositions | EXEC call | Caller | Orchestrates this procedure as part of a broader account position setup flow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.AddAccountPositionsInsert (procedure)
├── Trade.Hedge (table) [READ - NOLOCK]
├── History.Hedge (table) [READ - NOLOCK, index hint]
├── Hedge.AccountOpenPositions (table) [WRITER - INSERT]
├── Hedge.AccountClosedPositions (table) [WRITER - INSERT]
├── Internal.GetNetProfitHedgeWithPriceRateID (function) [CROSS APPLY]
└── Internal.GetNetOpenInUSD (function) [called for each open position]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Hedge | Table | Source of all open hedge positions for the server |
| History.Hedge | Table | Source of closed positions since @FromDate |
| Hedge.AccountOpenPositions | Table | Target for open position aggregates |
| Hedge.AccountClosedPositions | Table | Target for closed position P&L window |
| Internal.GetNetProfitHedgeWithPriceRateID | Function | CROSS APPLY to compute unrealized P&L per open hedge |
| Internal.GetNetOpenInUSD | Function | Converts lot count to USD net open amount |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AddAccountPositions | Stored Procedure | Calls this procedure as the data population step |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

Note: Uses `WITH (NOLOCK, index(IX_History_Hedge_CloseOccurred))` hint on History.Hedge - forces the query to use the CloseOccurred index to avoid a full scan on a large history table.

---

## 8. Sample Queries

### 8.1 Execute the procedure for a specific hedge server
```sql
EXEC [Hedge].[AddAccountPositionsInsert]
    @HedgeServerID = 1,
    @FromDate = '2026-03-18 00:00:00'
```

### 8.2 Verify resulting open positions
```sql
SELECT HedgeServerID, LiquidityAccountID, InstrumentID,
       UnrealizedNetPL, HedgedUnits, OccurredAt
FROM [Hedge].[AccountOpenPositions] WITH (NOLOCK)
WHERE HedgeServerID = 1
ORDER BY OccurredAt DESC
```

### 8.3 Verify resulting closed positions
```sql
SELECT HedgeServerID, LiquidityAccountID, InstrumentID, NetPL, ExecutionVolumeInUSD, OccurredAt
FROM [Hedge].[AccountClosedPositions] WITH (NOLOCK)
WHERE HedgeServerID = 1
ORDER BY OccurredAt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.AddAccountPositionsInsert | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.AddAccountPositionsInsert.sql*
