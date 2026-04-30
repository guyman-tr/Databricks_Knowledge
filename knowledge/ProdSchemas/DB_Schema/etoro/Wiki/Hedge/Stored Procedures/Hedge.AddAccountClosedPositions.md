# Hedge.AddAccountClosedPositions

> Inserts a single realized P&L record into Hedge.AccountClosedPositions for a given hedge server, liquidity account, and instrument.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Inserts into Hedge.AccountClosedPositions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.AddAccountClosedPositions` is a minimal single-row INSERT stored procedure that writes one realized P&L record into `Hedge.AccountClosedPositions`. It captures the net profit/loss and execution volume realized by a specific liquidity account on a specific instrument via a specific hedge server.

This procedure exists as a simple, single-record entry point for cases where the caller has one closed position event to record at a time - as opposed to `Hedge.AddAccountPositionsInsert`, which recalculates and bulk-inserts. The procedure is called directly (no callers in SSDT) suggesting it is invoked from application code when a hedge position is individually closed out.

`Hedge.AccountClosedPositions` is the real-time accumulation table for per-account realized P&L; the `ArchiveAccountClosedPositions` procedure periodically rolls it up into `History.AccountClosedPositions`.

---

## 2. Business Logic

### 2.1 Single-Row Realized P&L Insert

**What**: Records one realized P&L event for a hedge account/instrument pair.

**Columns/Parameters Involved**: `@HedgeServerID`, `@LiquidityAccountID`, `@InstrumentID`, `@NetPL`, `@ExecutionVolumeInUSD`

**Rules**:
- No duplicate check - the INSERT does not guard against duplicate records. The caller is responsible for idempotency.
- `@NetPL`: net realized profit/loss in USD. Positive = the hedge account profited (customer lost), negative = the hedge account lost (customer profited).
- `@ExecutionVolumeInUSD`: execution volume in USD for this closed position, used in hedge cost ratio calculations.
- No transaction - the INSERT is atomic by SQL Server default; no explicit BEGIN TRAN / COMMIT.
- OccurredAt is populated by the DEFAULT constraint on `Hedge.AccountClosedPositions` (GETUTCDATE()), not passed as a parameter.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | INTEGER | NO | - | CODE-BACKED | The hedge server instance that realized this closed position. Scopes the P&L to the server that managed the hedge. Implicit FK to Trade.HedgeServer. |
| 2 | @LiquidityAccountID | INTEGER | NO | - | CODE-BACKED | The liquidity (broker) account that held this hedge position. Identifies which broker account realized the P&L. Implicit FK to Trade.LiquidityAccounts. |
| 3 | @InstrumentID | INTEGER | NO | - | CODE-BACKED | The trading instrument on which the hedge position was closed. Implicit FK to Trade.Instrument. |
| 4 | @NetPL | decimal(14,4) | NO | - | CODE-BACKED | Net realized profit/loss for this closed hedge position in USD. Positive = hedge account profit (customer position moved against customer), negative = hedge account loss. |
| 5 | @ExecutionVolumeInUSD | decimal(14,4) | NO | - | CODE-BACKED | Notional execution volume in USD for this closed position. Used in HedgeCostReport as the denominator for hedge cost percentage calculations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeServerID | Trade.HedgeServer | Implicit | Scopes the P&L record to a specific hedge server |
| @LiquidityAccountID | Trade.LiquidityAccounts | Implicit | Identifies the liquidity account that closed the position |
| @InstrumentID | Trade.Instrument | Implicit | Identifies the traded instrument |

### 5.2 Referenced By (other objects point to this)

No stored procedure callers found in SSDT. Called from application code when a single hedge position is closed.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.AddAccountClosedPositions (procedure)
└── Hedge.AccountClosedPositions (table) [WRITER - INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountClosedPositions | Table | Inserts one realized P&L row |

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the SP to record a closed position
```sql
EXEC [Hedge].[AddAccountClosedPositions]
    @HedgeServerID = 1,
    @LiquidityAccountID = 101,
    @InstrumentID = 100,
    @NetPL = -1250.75,
    @ExecutionVolumeInUSD = 50000.00
```

### 8.2 Verify the inserted record
```sql
SELECT TOP 5 HedgeServerID, LiquidityAccountID, InstrumentID, NetPL, ExecutionVolumeInUSD, OccurredAt
FROM [Hedge].[AccountClosedPositions] WITH (NOLOCK)
WHERE HedgeServerID = 1 AND LiquidityAccountID = 101
ORDER BY OccurredAt DESC
```

### 8.3 Sum P&L by hedge server and instrument
```sql
SELECT HedgeServerID, InstrumentID,
       SUM(NetPL) AS TotalNetPL,
       SUM(ExecutionVolumeInUSD) AS TotalVolume
FROM [Hedge].[AccountClosedPositions] WITH (NOLOCK)
WHERE OccurredAt >= DATEADD(day, -1, GETUTCDATE())
GROUP BY HedgeServerID, InstrumentID
ORDER BY ABS(SUM(NetPL)) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.AddAccountClosedPositions | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.AddAccountClosedPositions.sql*
