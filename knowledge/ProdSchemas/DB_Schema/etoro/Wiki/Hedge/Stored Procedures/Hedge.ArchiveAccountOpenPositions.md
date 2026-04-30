# Hedge.ArchiveAccountOpenPositions

> Archives Hedge.AccountOpenPositions snapshots to History.AccountOpenPositions by keeping only the last snapshot per time interval, discarding intermediate rows within the window.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Reads Hedge.AccountOpenPositions; writes History.AccountOpenPositions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.ArchiveAccountOpenPositions` archives the real-time account open position snapshots (`Hedge.AccountOpenPositions`) to `History.AccountOpenPositions`. Unlike the closed positions archive which SUMs P&L, this procedure uses a "last-snapshot-wins" approach: for each (HedgeServerID, LiquidityAccountID, InstrumentID, time-interval) combination, it keeps only the most recent row (RowNum = 1) from the interval.

This design reflects the nature of the data: open position snapshots are point-in-time states, not cumulative events. The last snapshot in each interval is the most accurate representation of the position state at that time. The history table stores one row per time bucket as the end-of-interval state.

Called by `Hedge.ArchiveHedgeTables` and `Hedge.ArchiveHedgeTables_SS`.

---

## 2. Business Logic

### 2.1 Last-Snapshot-Per-Interval Archival

**What**: For each time bucket, retains only the most recent open position snapshot.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`, `@IntervalInMinutes`

**Rules**:
- Uses ROW_NUMBER() OVER (PARTITION BY HedgeServerID, LiquidityAccountID, InstrumentID, interval_bucket ORDER BY OccurredAt DESC) to rank rows within each bucket.
- Only RowNum = 1 (most recent OccurredAt per bucket) is inserted into History.
- All snapshot fields are preserved: `UnrealizedNetPL`, `PriceRateID`, `NetHedgedInUSD`, `HedgedUnits`.
- Interval bucket formula: `DATEDIFF(minute, '2010-01-01', OccurredAt) / @IntervalInMinutes`.
- Full transaction with TRY/CATCH and ROLLBACK on error.

### 2.2 Error Handling

**What**: Transactional insert with rollback and diagnostic re-raise.

**Rules**:
- Same pattern as ArchiveAccountClosedPositions: BEGIN TRY / TRANSACTION / COMMIT with CATCH / ROLLBACK / RAISERROR.

**Diagram**:
```
Hedge.AccountOpenPositions (many snapshots per interval)
  |
  | WHERE OccurredAt BETWEEN @StartDate AND @EndDate
  |
  | ROW_NUMBER() PARTITION BY (HS, LA, Inst, interval_bucket) ORDER BY OccurredAt DESC
  |
  | FILTER: RowNum = 1 (last snapshot per bucket)
  |
  v
History.AccountOpenPositions (one row per HS/LA/Inst/interval)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | datetime | NO | - | CODE-BACKED | Archive window start (inclusive): rows with OccurredAt >= @StartDate are candidates for archival. |
| 2 | @EndDate | datetime | NO | - | CODE-BACKED | Archive window end (exclusive): rows with OccurredAt < @EndDate are processed. |
| 3 | @IntervalInMinutes | int | NO | - | CODE-BACKED | Time bucket granularity in minutes. Determines how many open position snapshots are collapsed into one history row per partition key. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Hedge.AccountOpenPositions | READ (CTE) | Source of real-time open position snapshots |
| - | History.AccountOpenPositions | WRITER (INSERT) | Target history table for end-of-interval open position states |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.ArchiveHedgeTables | EXEC call | Caller | Main archive orchestrator |
| Hedge.ArchiveHedgeTables_SS | EXEC call | Caller | SQL Server Agent scheduled variant |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ArchiveAccountOpenPositions (procedure)
├── Hedge.AccountOpenPositions (table) [READ]
└── History.AccountOpenPositions (table) [WRITER - INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountOpenPositions | Table | Source of real-time open position snapshots |
| History.AccountOpenPositions | Table | Target for last-snapshot-per-interval history |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ArchiveHedgeTables | Stored Procedure | Calls this as part of the periodic archival job |
| Hedge.ArchiveHedgeTables_SS | Stored Procedure | Scheduled variant that also calls this procedure |

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
EXEC [Hedge].[ArchiveAccountOpenPositions]
    @StartDate = '2026-03-18 00:00:00',
    @EndDate   = '2026-03-19 00:00:00',
    @IntervalInMinutes = 15
```

### 8.2 Check archived open positions for a hedge server
```sql
SELECT TOP 10 HedgeServerID, LiquidityAccountID, InstrumentID,
       OccurredAt, UnrealizedNetPL, HedgedUnits
FROM [History].[AccountOpenPositions] WITH (NOLOCK)
WHERE HedgeServerID = 1 AND OccurredAt >= '2026-03-18 00:00:00'
ORDER BY OccurredAt DESC
```

### 8.3 Verify interval compression ratio
```sql
SELECT
    DATEDIFF(minute, '2010-01-01', OccurredAt) / 15 AS IntervalBucket,
    COUNT(*) AS SnapshotCount
FROM [Hedge].[AccountOpenPositions] WITH (NOLOCK)
WHERE OccurredAt BETWEEN '2026-03-18 00:00:00' AND '2026-03-18 01:00:00'
  AND HedgeServerID = 1 AND LiquidityAccountID = 101
GROUP BY DATEDIFF(minute, '2010-01-01', OccurredAt) / 15
ORDER BY IntervalBucket
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [System Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/14109638672/System+Overview) | Confluence | AccountPL (per account open positions) stored in History SQL DB; HedgeCostReportHistoryPerDay reads History.AccountOpenPositions for delta calculations |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ArchiveAccountOpenPositions | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.ArchiveAccountOpenPositions.sql*
