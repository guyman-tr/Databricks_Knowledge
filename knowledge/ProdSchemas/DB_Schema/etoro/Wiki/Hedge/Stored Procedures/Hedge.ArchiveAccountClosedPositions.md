# Hedge.ArchiveAccountClosedPositions

> Archives Hedge.AccountClosedPositions data to History.AccountClosedPositions by aggregating rows into configurable time intervals and moving them out of the real-time table.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Reads Hedge.AccountClosedPositions; writes History.AccountClosedPositions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.ArchiveAccountClosedPositions` is one of a family of archive procedures that compresses real-time hedge data into time-interval aggregates for long-term storage in the `History` schema. This procedure specifically handles the `AccountClosedPositions` table - the per-account, per-instrument realized P&L accumulation table.

The real-time table accumulates many fine-grained rows (one per closed position event). This procedure condenses them into one row per (HedgeServerID, LiquidityAccountID, InstrumentID, time-interval) by SUMming NetPL and ExecutionVolumeInUSD, and taking the MAX OccurredAt within each interval. The result is inserted into `History.AccountClosedPositions`.

This procedure is called by `Hedge.ArchiveHedgeTables` and `Hedge.ArchiveHedgeTables_SS` as part of the nightly/periodic archival job. The `@IntervalInMinutes` parameter controls the granularity of the compressed output (15 minutes is the typical interval, as seen in the comments).

---

## 2. Business Logic

### 2.1 Interval-Based Aggregation

**What**: Compresses fine-grained P&L events into coarser time buckets for history storage.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`, `@IntervalInMinutes`

**Rules**:
- Partitions rows into buckets: `DATEDIFF(minute, '2010-01-01', OccurredAt) / @IntervalInMinutes` (integer division groups rows into @IntervalInMinutes-wide windows).
- `OccurredAt` in the output = MAX(OccurredAt) within the bucket - the latest timestamp in the interval.
- `NetPL` and `ExecutionVolumeInUSD` are SUMMed within each bucket.
- Only rows with `OccurredAt >= @StartDate AND OccurredAt < @EndDate` are processed.
- The INSERT is wrapped in a transaction with TRY/CATCH + ROLLBACK on error.

### 2.2 Error Handling

**What**: Full transaction with rollback and error re-raise.

**Rules**:
- BEGIN TRY / BEGIN TRANSACTION / COMMIT: all rows are inserted atomically.
- BEGIN CATCH / ROLLBACK: on any error, the entire insert is rolled back.
- RAISERROR with the procedure name, error message, and line number for diagnostic logging.

**Diagram**:
```
Hedge.AccountClosedPositions
  |
  | WHERE OccurredAt BETWEEN @StartDate AND @EndDate
  |
  | GROUP BY (HedgeServerID, LiquidityAccountID, InstrumentID, interval bucket)
  | SUM(NetPL), SUM(ExecutionVolumeInUSD), MAX(OccurredAt)
  |
  v
History.AccountClosedPositions
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | datetime | NO | - | CODE-BACKED | Archive window start (inclusive): rows with OccurredAt >= @StartDate are included. Typically the last archive cutoff date. |
| 2 | @EndDate | datetime | NO | - | CODE-BACKED | Archive window end (exclusive): rows with OccurredAt < @EndDate are included. Typically the current archival run's end timestamp. |
| 3 | @IntervalInMinutes | int | NO | - | CODE-BACKED | Aggregation granularity in minutes. Rows within the same @IntervalInMinutes window are summed into a single output row. Typical value: 15 (as per developer comment in code). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Hedge.AccountClosedPositions | READ (CTE) | Source of real-time closed position data to be archived |
| - | History.AccountClosedPositions | WRITER (INSERT) | Target history table for aggregated closed position data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.ArchiveHedgeTables | EXEC call | Caller | Main archive orchestrator that calls this procedure |
| Hedge.ArchiveHedgeTables_SS | EXEC call | Caller | SQL Server Agent variant that also calls this procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ArchiveAccountClosedPositions (procedure)
├── Hedge.AccountClosedPositions (table) [READ]
└── History.AccountClosedPositions (table) [WRITER - INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountClosedPositions | Table | Source data for archival aggregation |
| History.AccountClosedPositions | Table | Target for time-interval aggregated history |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ArchiveHedgeTables | Stored Procedure | Calls this as part of the periodic hedge archival job |
| Hedge.ArchiveHedgeTables_SS | Stored Procedure | SQL Server Agent-scheduled variant that calls this procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH + TRANSACTION | Error handling | Full rollback on error; re-raises with procedure name and line number for diagnostics |

---

## 8. Sample Queries

### 8.1 Execute archival for a specific time window
```sql
EXEC [Hedge].[ArchiveAccountClosedPositions]
    @StartDate = '2026-03-18 00:00:00',
    @EndDate   = '2026-03-19 00:00:00',
    @IntervalInMinutes = 15
```

### 8.2 Verify data was archived
```sql
SELECT TOP 10 HedgeServerID, LiquidityAccountID, InstrumentID,
       OccurredAt, NetPL, ExecutionVolumeInUSD
FROM [History].[AccountClosedPositions] WITH (NOLOCK)
WHERE OccurredAt >= '2026-03-18 00:00:00'
ORDER BY OccurredAt DESC
```

### 8.3 Check real-time vs. history row counts for a period
```sql
SELECT 'RealTime' AS Source, COUNT(*) AS RowCount
FROM [Hedge].[AccountClosedPositions] WITH (NOLOCK)
WHERE OccurredAt BETWEEN '2026-03-18 00:00:00' AND '2026-03-18 01:00:00'
UNION ALL
SELECT 'History', COUNT(*)
FROM [History].[AccountClosedPositions] WITH (NOLOCK)
WHERE OccurredAt BETWEEN '2026-03-18 00:00:00' AND '2026-03-18 01:00:00'
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [System Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/14109638672/System+Overview) | Confluence | Hedge Cost: AccountPL data (netting rates) stored in History SQL DB; archive procedures feed the historical storage layer used by HedgeCostAPI for INSight display |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ArchiveAccountClosedPositions | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.ArchiveAccountClosedPositions.sql*
