# Hedge.ArchiveAccountStatus

> Archives Hedge.AccountStatus snapshots to History.AccountStatus by retaining only the last snapshot per time interval per hedge server and liquidity account.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Reads Hedge.AccountStatus; writes History.AccountStatus |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.ArchiveAccountStatus` archives the `Hedge.AccountStatus` real-time table - which holds the current financial state of each liquidity account (balance, equity, margin, P&L) - into `History.AccountStatus` for long-term storage.

`Hedge.AccountStatus` is updated frequently as market prices change and positions are opened/closed. The archive procedure condenses this high-frequency time series into one row per time bucket by keeping the most recent snapshot within each interval. This "end-of-interval state" approach is appropriate since account status is a current state (not an accumulative event), and the last snapshot in the interval best represents the state at that time.

The historical data in `History.AccountStatus` is read by `Hedge.HedgeCostReportHistoryPerDay` and `Hedge.HedgeCostReportHistoryPerHour` to compute account-level P&L delta for the hedge cost report (the "Account Diff" component).

Called by `Hedge.ArchiveHedgeTables` and `Hedge.ArchiveHedgeTables_SS`.

---

## 2. Business Logic

### 2.1 Last-Snapshot-Per-Interval Archival of Account Financial State

**What**: For each hedge server/account/interval bucket, retains only the latest account status snapshot.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`, `@IntervalInMinutes`

**Rules**:
- Uses ROW_NUMBER() OVER (PARTITION BY HedgeServerID, LiquidityAccountID, interval_bucket ORDER BY OccurredAt DESC) to rank snapshots.
- RowNum = 1 (most recent per bucket) is inserted into History.AccountStatus.
- All financial columns are preserved: `Balance`, `NetPL`, `Equity`, `UsedMargin`, `UsableMargin`, `MaintenanceMargin`, `CurrentLeverage`, `Cushion`, `GrossPositionsValue`.
- Both `OccurredAt` (server's snapshot time) and `OccurredAtAccount` (account-side timestamp) are preserved.
- Full transaction with TRY/CATCH and ROLLBACK on error.

### 2.2 Downstream Usage in HedgeCostReport

**What**: The history data is used to compute daily/hourly balance deltas for hedge cost reporting.

**Rules**:
- `HedgeCostReportHistoryPerDay` reads `History.AccountStatus` and computes `Balance` deltas between consecutive days to get account-level realized hedge cost ("Account Diff - Realized").
- `NetPL` from History.AccountStatus is used for "Account P&L - Unrealized" column in the report.

**Diagram**:
```
Hedge.AccountStatus (high-frequency snapshots)
  |
  | WHERE OccurredAt BETWEEN @StartDate AND @EndDate
  | ROW_NUMBER() PARTITION BY (HS, LA, interval_bucket) ORDER BY OccurredAt DESC
  | FILTER: RowNum = 1
  |
  v
History.AccountStatus (end-of-interval states)
  |
  +-> HedgeCostReportHistoryPerDay: Balance delta between days = account-level hedge cost
  +-> HedgeCostReportHistoryPerHour: same at hourly granularity
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | datetime | NO | - | CODE-BACKED | Archive window start (inclusive). Rows with OccurredAt >= @StartDate are candidates for archival. |
| 2 | @EndDate | datetime | NO | - | CODE-BACKED | Archive window end (exclusive). Rows with OccurredAt < @EndDate are processed. |
| 3 | @IntervalInMinutes | int | NO | - | CODE-BACKED | Time bucket granularity. Determines the compression ratio - each output row covers @IntervalInMinutes worth of input snapshots. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Hedge.AccountStatus | READ (CTE) | Source of real-time account financial state snapshots |
| - | History.AccountStatus | WRITER (INSERT) | Target for end-of-interval account status history |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.ArchiveHedgeTables | EXEC call | Caller | Main periodic archive orchestrator |
| Hedge.ArchiveHedgeTables_SS | EXEC call | Caller | SQL Server Agent scheduled variant |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ArchiveAccountStatus (procedure)
├── Hedge.AccountStatus (table) [READ]
└── History.AccountStatus (table) [WRITER - INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountStatus | Table | Source of real-time account financial state data |
| History.AccountStatus | Table | Target for compressed, interval-based history |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ArchiveHedgeTables | Stored Procedure | Calls this as part of the archival job |
| Hedge.ArchiveHedgeTables_SS | Stored Procedure | Scheduled variant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH + TRANSACTION | Error handling | Full rollback on error with diagnostic RAISERROR |

---

## 8. Sample Queries

### 8.1 Execute archival for a time window
```sql
EXEC [Hedge].[ArchiveAccountStatus]
    @StartDate = '2026-03-18 00:00:00',
    @EndDate   = '2026-03-19 00:00:00',
    @IntervalInMinutes = 15
```

### 8.2 View archived account status
```sql
SELECT TOP 10 HedgeServerID, LiquidityAccountID, OccurredAt,
       Balance, NetPL, Equity, UsedMargin, CurrentLeverage
FROM [History].[AccountStatus] WITH (NOLOCK)
WHERE HedgeServerID = 1 AND OccurredAt >= '2026-03-18 00:00:00'
ORDER BY OccurredAt DESC
```

### 8.3 Calculate balance delta between two archived points
```sql
SELECT a.HedgeServerID, a.LiquidityAccountID,
       b.OccurredAt AS NewerDate, a.OccurredAt AS OlderDate,
       b.Balance - a.Balance AS BalanceDelta
FROM [History].[AccountStatus] a WITH (NOLOCK)
JOIN [History].[AccountStatus] b WITH (NOLOCK)
  ON a.HedgeServerID = b.HedgeServerID
 AND a.LiquidityAccountID = b.LiquidityAccountID
WHERE CAST(a.OccurredAt AS DATE) = '2026-03-17'
  AND CAST(b.OccurredAt AS DATE) = '2026-03-18'
ORDER BY ABS(b.Balance - a.Balance) DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [System Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/14109638672/System+Overview) | Confluence | AccountPL data stored in History SQL DB; Balance delta from History.AccountStatus is the "Account Diff - Realized" component in the INSight HedgeCost report |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ArchiveAccountStatus | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.ArchiveAccountStatus.sql*
