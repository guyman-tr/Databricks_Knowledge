# Hedge.ArchiveCustomerOpenPositions

> Archives Hedge.CustomerOpenPositions snapshots to History.CustomerOpenPositions by retaining the last snapshot per time interval per hedge server and instrument.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Reads Hedge.CustomerOpenPositions; writes History.CustomerOpenPositions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.ArchiveCustomerOpenPositions` archives `Hedge.CustomerOpenPositions` - the real-time table of aggregate open customer position state per hedge server and instrument - to `History.CustomerOpenPositions`. It uses the same "last-snapshot-wins" approach as `ArchiveAccountOpenPositions`.

`Hedge.CustomerOpenPositions` captures unrealized P&L, commission on open, unit counts, and price rate at each snapshot. These are point-in-time states, so the history table preserves the most recent snapshot per time bucket (rather than summing).

The history data feeds `HedgeCostReportHistoryPerDay` and `HedgeCostReportHistoryPerHour`, which compute delta values of `UnrealizedPL` and `CommissionOnOpen` between consecutive day/hour buckets. These deltas represent the "Clients P&L - Unrealized" and "Etoro Commission - Unrealized" components of the hedge cost report.

Called by `Hedge.ArchiveHedgeTables` (the customer open positions archive is included in the main archive job but not in the SS variant, based on the search results).

---

## 2. Business Logic

### 2.1 Last-Snapshot-Per-Interval for Customer Open Positions

**What**: Retains the end-of-interval state of customer open positions for history storage.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`, `@IntervalInMinutes`

**Rules**:
- ROW_NUMBER() OVER (PARTITION BY HedgeServerID, InstrumentID, interval_bucket ORDER BY OccurredAt DESC) - note: no LiquidityAccountID partitioning (customer positions are server+instrument level).
- RowNum = 1 (latest per bucket) is inserted into History.
- All snapshot columns preserved: `UnrealizedPL`, `CommissionOnOpen`, `UnrealizedZeroPL`, `OpenedBuyUnits`, `OpenedSellUnits`, `OpenedUnits`, `PriceRateID`, `NetOpenInUSD`.
- Full transaction with TRY/CATCH.

### 2.2 Downstream Use in HedgeCostReport

**What**: Delta of history snapshots gives unrealized customer P&L change for the hedge cost report.

**Rules**:
- `HedgeCostReportHistoryPerDay` reads `History.CustomerOpenPositions` and computes `UnrealizedPL` delta between adjacent day buckets = "Clients P&L - Unrealized".
- `CommissionOnOpen` delta = "Etoro Commission - Unrealized".
- `UnrealizedZeroPL` delta = "Etoro Zero - Unrealized".

**Diagram**:
```
Hedge.CustomerOpenPositions (many snapshots per interval)
  |
  | ROW_NUMBER() PARTITION BY (HS, Inst, interval_bucket) ORDER BY OccurredAt DESC
  | FILTER: RowNum = 1
  |
  v
History.CustomerOpenPositions (one row per HS/Inst/interval)
  |
  +-> HedgeCostReportHistoryPerDay/PerHour:
      DELTA(UnrealizedPL) = "Clients P&L - Unrealized"
      DELTA(CommissionOnOpen) = "Etoro Commission - Unrealized"
      DELTA(UnrealizedZeroPL) = "Etoro Zero - Unrealized"
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | datetime | NO | - | CODE-BACKED | Archive window start (inclusive). Rows with OccurredAt >= @StartDate are candidates. |
| 2 | @EndDate | datetime | NO | - | CODE-BACKED | Archive window end (exclusive). Rows with OccurredAt < @EndDate are processed. |
| 3 | @IntervalInMinutes | int | NO | - | CODE-BACKED | Time bucket granularity in minutes. Controls the compression from high-frequency snapshots to historical state intervals. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Hedge.CustomerOpenPositions | READ (CTE) | Source of real-time customer open position snapshots |
| - | History.CustomerOpenPositions | WRITER (INSERT) | Target for end-of-interval open position history |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.ArchiveHedgeTables | EXEC call | Caller | Main archive orchestrator |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ArchiveCustomerOpenPositions (procedure)
├── Hedge.CustomerOpenPositions (table) [READ]
└── History.CustomerOpenPositions (table) [WRITER - INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.CustomerOpenPositions | Table | Source of real-time open position snapshot data |
| History.CustomerOpenPositions | Table | Target for compressed history |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ArchiveHedgeTables | Stored Procedure | Calls this as part of the archival job |

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

### 8.1 Execute archival
```sql
EXEC [Hedge].[ArchiveCustomerOpenPositions]
    @StartDate = '2026-03-18 00:00:00',
    @EndDate   = '2026-03-19 00:00:00',
    @IntervalInMinutes = 15
```

### 8.2 View archived customer open positions
```sql
SELECT TOP 10 HedgeServerID, InstrumentID, OccurredAt,
       UnrealizedPL, CommissionOnOpen, OpenedBuyUnits, OpenedSellUnits
FROM [History].[CustomerOpenPositions] WITH (NOLOCK)
WHERE HedgeServerID = 1 AND OccurredAt >= '2026-03-18 00:00:00'
ORDER BY OccurredAt DESC
```

### 8.3 Calculate P&L delta between two intervals
```sql
SELECT a.HedgeServerID, a.InstrumentID,
       b.OccurredAt AS NewerDate, a.OccurredAt AS OlderDate,
       b.UnrealizedPL - a.UnrealizedPL AS UnrealizedPLDelta
FROM [History].[CustomerOpenPositions] a WITH (NOLOCK)
JOIN [History].[CustomerOpenPositions] b WITH (NOLOCK)
  ON a.HedgeServerID = b.HedgeServerID AND a.InstrumentID = b.InstrumentID
WHERE CAST(a.OccurredAt AS DATE) = '2026-03-17'
  AND CAST(b.OccurredAt AS DATE) = '2026-03-18'
ORDER BY ABS(b.UnrealizedPL - a.UnrealizedPL) DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [System Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/14109638672/System+Overview) | Confluence | CustomerPL (unrealized) from History.CustomerOpenPositions drives "Clients P&L - Unrealized" and "Etoro Commission - Unrealized" in INSight HedgeCost display |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 caller analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ArchiveCustomerOpenPositions | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.ArchiveCustomerOpenPositions.sql*
