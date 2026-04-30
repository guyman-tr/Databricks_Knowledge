# History.DeltaDiff

> Quarter-hourly downsampled archive of system-wide financial reconciliation snapshots, storing the first PnL delta record from each 15-minute window from Trade.DeltaDiff for long-term trend analysis.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | DeltaDiffID (bigint, NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (CLUSTERED on ValidFrom, NONCLUSTERED PK on DeltaDiffID) |

---

## 1. Business Meaning

This table is a **quarter-hourly sampled archive** of `Trade.DeltaDiff`. Trade.DeltaDiff records system-wide financial reconciliation snapshots in near-real-time (approximately every 15 seconds), capturing the aggregate realized and unrealized PnL, commissions, and discrepancies across all trading accounts. This History table stores only **one record per 15-minute window** - the first snapshot from each quarter-hour - serving as a compact long-term historical series for trend analysis and auditing.

The "delta diff" concept represents the reconciliation check: each snapshot captures the aggregate financial position of the entire eToro trading system at a point in time. The `Diff` column is the sum of all account-level realized and unrealized sums, representing the total discrepancy being tracked. Risk managers and the finance team use this data to monitor system-wide PnL accumulation over time and detect anomalies.

Data flows: `Trade.DeltaDiffDataAdd` (called by external BSL/reconciliation service) -> `Trade.DeltaDiff` (high-frequency, ~every 15 seconds) -> `History.AddFirstInQuarterDeltaDif` (scheduled job) -> `History.DeltaDiff` (quarter-hourly archive). The History table retains data from 2010.

---

## 2. Business Logic

### 2.1 Quarter-Hour Downsampling

**What**: Only the first snapshot from each 15-minute window is preserved in this history table.

**Columns/Parameters Involved**: `ValidFrom`, `DeltaDiffID`

**Rules**:
- `History.AddFirstInQuarterDeltaDif` runs periodically and partitions Trade.DeltaDiff records into 15-minute buckets using: `DATEDIFF(mi, ValidFrom, @StartTime) / 15`.
- From each bucket, only `ROW_NUMBER() = 1` (the earliest record) is copied.
- If no new records exist AND Trade.DeltaDiff has not been updated for 15+ minutes (market closure), the last record from Trade.DeltaDiff is inserted as an end-of-week marker.
- The procedure is idempotent: it tracks the last inserted ValidFrom to know where to resume.

**Diagram**:
```
Trade.DeltaDiff (high frequency ~15s):
  DiffID=180, ValidFrom=09:00:04  <- first in 09:00-09:14 window
  DiffID=360, ValidFrom=09:00:19  <- second (ignored)
  DiffID=540, ValidFrom=09:00:34  <- third (ignored)
  ... (dozens more) ...
  DiffID=4680, ValidFrom=09:14:58  <- last in window (ignored)
  DiffID=4860, ValidFrom=09:15:03  <- first in 09:15-09:29 window

History.DeltaDiff (quarter-hourly):
  DiffID=180, ValidFrom=09:00:04  <- kept (first in 09:00 window)
  DiffID=4860, ValidFrom=09:15:03 <- kept (first in 09:15 window)
```

### 2.2 ValidFrom/ValidTo Interval Semantics

**What**: The ValidFrom/ValidTo pair defines the time window during which this snapshot was the "current" state in Trade.DeltaDiff.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`

**Rules**:
- `ValidFrom` = GETUTCDATE() at the time Trade.DeltaDiffDataAdd was called (when the snapshot was captured).
- `ValidTo` is set by Trade.DeltaDiffDataAdd: for the newest record in Trade.DeltaDiff it is `'2100-01-01'` (infinity sentinel). When a newer record arrives, the previous record's `ValidTo` is updated to the new record's `ValidFrom`.
- This means `ValidTo - ValidFrom` for historical records equals approximately the interval between consecutive Trade.DeltaDiff snapshots (~4 seconds in sample data).
- Records from History.DeltaDiff with `ValidTo = '2100-01-01'` are the records that were "current" at the time History.AddFirstInQuarterDeltaDif copied them (not necessarily still current in Trade.DeltaDiff).

### 2.3 Financial Snapshot Columns

**What**: Each snapshot captures nine distinct financial aggregates for the entire trading system.

**Columns/Parameters Involved**: All `dbo.dtPrice` (decimal(16,8)) columns

**Rules**:
- `Diff = AccountRealizedSum + AccountsUnRealizedSum` (verified from sample data: -411467.36 + -192987.55 = -604454.91)
- `RealizedPNLWCom = RealizedPNL + RealizedCommission` (net realized outcome including commissions)
- `UnRealizedPNLWCom = UnRealizedPNL + UnRealizedCommission` (net unrealized outcome including commissions)
- `Diff1AccountBalance`, `Diff1AccountNetPL`, `DiffAccountBalance`, `DiffAccountNetPL`, `FullyAccountBalance`, `FullyAccountNetPL` are all 0 in all available data - these appear to have been added to the schema for future use but are not currently populated.
- All amounts are in USD (system base currency).

---

## 3. Data Overview

| DeltaDiffID | AccountRealizedSum | AccountsUnRealizedSum | Diff | RealizedPNL | UnRealizedPNL | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|---|---|
| 4810560 | -411,467.36 | -192,987.55 | -604,454.91 | -329,453.73 | -1,519,672.16 | 2011-04-15 21:28 | 2011-04-15 21:28+4s | System snapshot at 21:28 UTC on 2011-04-15: total account net position -$604K (sum of realized -$411K + unrealized -$193K). This is the quarter-hour archive snapshot retained from the 21:15-21:29 window. |
| 4810380 | -411,467.36 | -192,987.55 | -604,454.91 | -329,453.73 | -1,519,672.16 | 2011-04-15 21:13 | 2011-04-15 21:13+4s | Previous quarter-hour snapshot (21:00-21:14 window). Identical values to the next window - system totals unchanged between windows (no new activity in this period). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DeltaDiffID | bigint | NO | - | CODE-BACKED | Unique identifier for this snapshot record. Obtained via Internal.GetDeltaDiffID (sequence from Internal.GenDeltaDiffID). The same DeltaDiffID value is stored in both Trade.DeltaDiff and History.DeltaDiff when a record is copied. Serves as the NONCLUSTERED PK. |
| 2 | AccountRealizedSum | dbo.dtPrice (decimal(16,8)) | NO | - | CODE-BACKED | Aggregate realized PnL sum across all trading accounts at snapshot time, in USD. Represents the cumulative closed-position PnL from the account system. Negative values indicate net losses across all accounts. |
| 3 | AccountsUnRealizedSum | dbo.dtPrice (decimal(16,8)) | NO | - | CODE-BACKED | Aggregate unrealized PnL sum across all trading accounts at snapshot time, in USD. Represents the mark-to-market value of all open positions. Negative values indicate open positions are collectively losing. |
| 4 | Diff | dbo.dtPrice (decimal(16,8)) | NO | - | VERIFIED | The total reconciliation delta: AccountRealizedSum + AccountsUnRealizedSum. Represents the combined net financial position of the entire system (all accounts, realized + unrealized). Used to detect and monitor system-wide discrepancies. |
| 5 | Diff1AccountBalance | dbo.dtPrice (decimal(16,8)) | NO | - | NAME-INFERRED | A balance difference metric, purpose not populated in current data (all 0 in sample). Added to schema for future reconciliation use. Likely represents the discrepancy between the "Account 1" (primary account) balance and the expected value. |
| 6 | Diff1AccountNetPL | dbo.dtPrice (decimal(16,8)) | NO | - | NAME-INFERRED | Net P&L difference for "Account 1" reconciliation. Not currently populated (all 0). Intended to capture single-account-level P&L discrepancy. |
| 7 | DiffAccountBalance | dbo.dtPrice (decimal(16,8)) | NO | - | NAME-INFERRED | Difference in total account balance across the reconciliation check. Not currently populated (all 0 in all available history). |
| 8 | DiffAccountNetPL | dbo.dtPrice (decimal(16,8)) | NO | - | NAME-INFERRED | Difference in total account net P&L. Not currently populated (all 0 in all available history). |
| 9 | FullyAccountBalance | dbo.dtPrice (decimal(16,8)) | NO | - | NAME-INFERRED | Fully reconciled total account balance. Not currently populated (all 0 in all available history). Intended as the "ground truth" balance for reconciliation comparison. |
| 10 | FullyAccountNetPL | dbo.dtPrice (decimal(16,8)) | NO | - | NAME-INFERRED | Fully reconciled total account net P&L. Not currently populated (all 0 in all available history). |
| 11 | RealizedCommission | dbo.dtPrice (decimal(16,8)) | NO | - | CODE-BACKED | Total realized commissions collected across all accounts, in USD. Positive values indicate commissions earned. Example: $740,921 in sample = total commissions on closed positions. |
| 12 | RealizedPNL | dbo.dtPrice (decimal(16,8)) | NO | - | CODE-BACKED | Total realized P&L from closed positions across all accounts, excluding commissions, in USD. Negative = aggregate customer profit (customer wins, eToro loses on CFDs), or aggregate losses if positive (market-maker perspective depends on hedging model). |
| 13 | RealizedPNLWCom | dbo.dtPrice (decimal(16,8)) | NO | - | VERIFIED | Realized P&L including commissions: RealizedPNL + RealizedCommission. Represents the net financial outcome from all closed positions with fees. Example: -329,453.73 + 740,921.09 = 411,467.36. |
| 14 | UnRealizedCommission | dbo.dtPrice (decimal(16,8)) | NO | - | CODE-BACKED | Total unrealized commissions on open positions (e.g., overnight fees accrued but not yet settled), in USD. |
| 15 | UnRealizedPNL | dbo.dtPrice (decimal(16,8)) | NO | - | CODE-BACKED | Total mark-to-market P&L of all open positions, excluding unrealized commissions, in USD. |
| 16 | UnRealizedPNLWCom | dbo.dtPrice (decimal(16,8)) | NO | - | VERIFIED | Unrealized P&L including unrealized commissions: UnRealizedPNL + UnRealizedCommission. Example: -1,519,672.16 + 36,328.34 = -1,483,343.82. |
| 17 | ValidFrom | datetime | NO | - | VERIFIED | UTC timestamp when this snapshot was captured in Trade.DeltaDiff. Clustered index key - primary access pattern is time-range queries. Set to GETUTCDATE() at insert time in Trade.DeltaDiffDataAdd. |
| 18 | ValidTo | datetime | NO | - | VERIFIED | UTC timestamp when this snapshot was superseded in Trade.DeltaDiff. '2100-01-01' sentinel = this was the most-recent record when copied to History. For historical records: ValidTo = ValidFrom of the next snapshot (~4 seconds later in Trade.DeltaDiff). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DeltaDiffID | Trade.DeltaDiff | Implicit | Same DeltaDiffID exists in both tables - History row is a downsampled copy from Trade |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.AddFirstInQuarterDeltaDif | History.DeltaDiff | Writer | Populates by copying first-per-quarter-hour records from Trade.DeltaDiff |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.DeltaDiff (table)
- Leaf node - no code-level dependencies
- Populated from Trade.DeltaDiff (table) via History.AddFirstInQuarterDeltaDif (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.dtPrice | User Defined Type | All 15 financial columns use this UDT (decimal(16,8) NULL) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.AddFirstInQuarterDeltaDif | Stored Procedure | Writer - inserts downsampled records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CIX_History_DeltaDiff__ValidFrom | CLUSTERED | ValidFrom ASC | - | - | Active |
| PK_History_DeltaDiffDataAdd | NONCLUSTERED (PK) | DeltaDiffID ASC | - | - | Active |

Both indexes have FILLFACTOR = 90 (10% free space for inserts).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_History_DeltaDiffDataAdd | PRIMARY KEY | Uniqueness on DeltaDiffID |

---

## 8. Sample Queries

### 8.1 System-wide PnL trend over a date range (quarter-hourly)
```sql
SELECT ValidFrom, Diff, RealizedPNL, UnRealizedPNL,
       RealizedCommission, UnRealizedCommission
FROM [History].[DeltaDiff] WITH (NOLOCK)
WHERE ValidFrom BETWEEN '2024-01-01' AND '2024-01-07'
ORDER BY ValidFrom
```

### 8.2 Most recent snapshot (current system state)
```sql
SELECT TOP 1 DeltaDiffID, Diff, RealizedPNLWCom, UnRealizedPNLWCom,
             AccountRealizedSum, AccountsUnRealizedSum, ValidFrom
FROM [History].[DeltaDiff] WITH (NOLOCK)
ORDER BY ValidFrom DESC
```

### 8.3 Daily aggregate summary from quarter-hourly snapshots
```sql
SELECT CAST(ValidFrom AS DATE) AS TradeDate,
       AVG(Diff) AS AvgDiff,
       MIN(Diff) AS MinDiff,
       MAX(Diff) AS MaxDiff,
       AVG(RealizedCommission) AS AvgRealizedCommission,
       COUNT(*) AS SnapshotCount
FROM [History].[DeltaDiff] WITH (NOLOCK)
WHERE ValidFrom >= '2024-01-01'
  AND ValidTo < '2100-01-01'  -- exclude "open" records
GROUP BY CAST(ValidFrom AS DATE)
ORDER BY TradeDate
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.9/10 (Elements: 8.3/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 6 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.DeltaDiff | Type: Table | Source: etoro/etoro/History/Tables/History.DeltaDiff.sql*
