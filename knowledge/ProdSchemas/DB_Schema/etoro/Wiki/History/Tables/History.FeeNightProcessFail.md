# History.FeeNightProcessFail

> Error log capturing positions for which overnight or weekend fee collection failed during the nightly fee processing batch, partitioned by CID modulo 10 to match the source position data sharding.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PK_FeeNightProcessFail: NONCLUSTERED on (CID, PositionID, PartitionCol, Occurred) |
| **Partition** | Yes - PS_PositionTbl on PartitionCol (CID % 10), 10 partitions |
| **Indexes** | 1 (NONCLUSTERED PK, FILLFACTOR=90, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

This table is the permanent error log for the overnight and weekend fee collection batch process. When `Trade.PayForFeeProcess` fails to collect a fee from a position - due to SQL errors during balance updates, credit adjustments, or other exceptions - the failed position record is captured here for investigation and remediation.

The nightly fee process runs sharded across 10 partitions (CID % 10), each processed by a separate SQL Agent job. For each partition, `Trade.PayForFeeProcess` iterates through positions in `Trade.FeeNightProcess` (pending with StatusID=0), attempting to deduct the overnight or weekend fee from each customer's balance. On failure (CATCH block), the position is marked StatusID=-1 in `Trade.FeeNightProcess`. After processing the entire partition, any StatusID=-1 positions are bulk-inserted here and a RAISERROR is raised. The monitoring procedure `Monitor.AlertFeeProcess_DataDog` queries this table between 03:00-05:00 UTC and alerts via Datadog if any new failures appeared in the last 10 hours.

With 0 rows currently, the fee process has either not produced failures in this environment or errors have been resolved. The FILLFACTOR=90 on the PK and the partition scheme mirror `Trade.PositionTbl`, ensuring partition-aligned access patterns between the fee queue and this error log.

---

## 2. Business Logic

### 2.1 Fee Process Failure Capture Flow

**What**: A two-stage failure handling pattern: first flag failures in Trade.FeeNightProcess (StatusID=-1), then bulk-copy all failures to this permanent log after the partition completes.

**Columns/Parameters Involved**: `PositionID`, `CID`, `FeeInDollars`, `ErrorMessage`, `StatusID`, `Occurred`

**Rules**:
- Failures only land here when Trade.PayForFeeProcess CATCH block fires (SQL error during fee application)
- The INSERT into this table is a bulk copy: `INSERT INTO History.FeeNightProcessFail ... SELECT FROM Trade.FeeNightProcess WHERE StatusID != 1 AND PartitionCol = @Partition`
- StatusID in this table reflects the failure code from Trade.FeeNightProcess (always -1 for error)
- Occurred DEFAULT is GETUTCDATE() - set at the time of bulk-insertion, not the original fee processing time
- After insertion, RAISERROR is raised to alert operators

**Diagram**:
```
Trade.PayForFeeProcess(@Partition) iterates Trade.FeeNightProcess WHERE StatusID=0:
  |
  +-- FOR EACH position:
  |     BEGIN TRY
  |       Update Trade.PositionTbl (apply fee)
  |       Customer.SetBalanceClameFee (deduct from balance)
  |       UPDATE Trade.FeeNightProcess SET StatusID=1 (success)
  |     END TRY
  |     BEGIN CATCH
  |       UPDATE Trade.FeeNightProcess SET StatusID=-1, ErrorMessage=error
  |     END CATCH
  |
  +-- AFTER all positions processed:
       IF EXISTS (Trade.FeeNightProcess WHERE StatusID=-1 AND PartitionCol=@Partition)
         INSERT INTO History.FeeNightProcessFail (bulk copy of all failed rows)
         RAISERROR('Select from Trade.FeeNightProcess where StatusID=-1 returned rows', 16, 1)
```

### 2.2 Overnight vs. Weekend Fee Differentiation

**What**: The Fee column distinguishes between regular overnight fees (charged daily) and end-of-week fees (charged on weekends).

**Columns/Parameters Involved**: `Fee`, `FeeInDollars`, `EndOfWeekFee`

**Rules**:
- Fee=1 = regular overnight fee (nightly, @IsWeekendFee=0 in the processing logic)
- Fee != 1 (any other value) = weekend/end-of-week fee (@IsWeekendFee=1)
- FeeInDollars: the specific fee amount that failed to be applied to this position
- EndOfWeekFee: the cumulative end-of-week fee amount for this position at time of failure
- Weekend fees update Trade.PositionTbl.LastEOWClameDate; overnight fees update LastOverNightClameDate

### 2.3 Datadog Monitoring Alert Window

**What**: Monitor.AlertFeeProcess_DataDog checks this table only during the expected fee processing window (03:00-05:00 UTC), avoiding false alerts outside the batch window.

**Columns/Parameters Involved**: `Occurred`

**Rules**:
- Monitor queries: `SELECT TOP 1 1 FROM History.FeeNightProcessFail WHERE Occurred > DATEADD(hour, -10, @now)`
- Only active between 03:00 and 05:00 UTC
- Returns 1 (alert) if any rows exist within last 10 hours during the window
- Returns 0 (OK) outside the 03:00-05:00 window regardless of table content

### 2.4 CID-Based Partitioning

**What**: The table uses the same PS_PositionTbl partition scheme as Trade.PositionTbl, ensuring co-located access between fee errors and position data.

**Columns/Parameters Involved**: `PartitionCol`, `CID`

**Rules**:
- PartitionCol = CID % 10 (computed, PERSISTED)
- 10 partition shards (0-9), matching the 10 SQL Agent jobs (ClaimFeeFromStocks00-05 / FeeNightProcess shards)
- PK includes PartitionCol as a partition elimination key, enabling single-partition scans when querying by CID

---

## 3. Data Overview

| PositionID | CID | IsBuy | FeeInDollars | ErrorMessage | Fee | Occurred | Meaning |
|---|---|---|---|---|---|---|---|
| (empty) | (empty) | (empty) | (empty) | (empty) | (empty) | (empty) | Table currently has 0 rows. The nightly fee process has produced no errors in this environment, or failed positions were resolved and this log is not pruned. Future rows will show positions where balance deduction failed during overnight or weekend fee collection. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | The trading position for which overnight/weekend fee collection failed. Sourced from Trade.FeeNightProcess. Part of the composite PK. Implicit FK to Trade.PositionTbl or History.Position_Active (the PayForFeeProcess checks both - live positions are in Trade.PositionTbl, already-closed positions are in History.Position_Active). |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID who owns the position. Part of the composite PK and the partition function input. The fee deduction via Customer.SetBalanceClameFee operates on this customer's balance. |
| 3 | PartitionCol | int (computed) | NO | - | CODE-BACKED | Computed persisted column: CID % 10. Partition elimination key matching PS_PositionTbl. Part of the PK. Ensures this error log co-partitions with Trade.PositionTbl for efficient joins. Values 0-9. |
| 4 | IsBuy | bit | NO | - | CODE-BACKED | Position direction at time of fee failure. 1=buy (long), 0=sell (short). Preserved from Trade.FeeNightProcess for context in error investigation. |
| 5 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror ID if this position was opened as part of a mirror/CopyTrader relationship. NULL for independent positions. References History.Mirror for portfolio-copier relationships. Used in Customer.SetBalanceClameFee to adjust mirror credit alongside customer balance. |
| 6 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position ID for copy-trade hierarchies. NULL for top-level positions. When non-null, this position is a child (copied) position under the parent in a mirror tree. |
| 7 | FeeInDollars | decimal(38,7) | YES | - | CODE-BACKED | The overnight or weekend fee amount in USD that failed to be deducted from the customer's balance. High precision (38,7) matches the fee calculation output. The failed amount - this was neither applied to Trade.PositionTbl.EndOfWeekFee nor deducted from the customer balance. |
| 8 | EndOfWeekFee | money | NO | - | CODE-BACKED | Cumulative end-of-week fee accumulated on this position up to the point of failure. Represents the total weekend fee liability for this position, not just the current failed amount. |
| 9 | Amount | money | NO | - | CODE-BACKED | Position size (notional amount) at time of fee processing. Used for context in determining the magnitude of the fee relative to position size. |
| 10 | CustomerCredit | money | YES | - | CODE-BACKED | The customer's current credit balance at time of the failed fee attempt. Used by Customer.SetBalanceClameFee to validate available balance before deduction. NULL if credit information was not available. |
| 11 | MirrorCredit | decimal(16,8) | YES | - | CODE-BACKED | The mirror/portfolio credit amount at time of failure. Applicable only when MirrorID is non-null. High precision (16,8) for accurate credit accounting across mirror portfolios. |
| 12 | IsActive | tinyint | NO | - | CODE-BACKED | Position active state at time of fee processing. 1=position was open/active when the fee attempt was made; 0=position was closed. PayForFeeProcess uses this to determine notification routing (FeeQueueInMem IsMirrorActive field). |
| 13 | Fee | tinyint | YES | - | CODE-BACKED | Fee type indicator. 1=regular overnight fee (daily charge). Any other value=end-of-week/weekend fee. Determines which timestamp is updated on Trade.PositionTbl (LastOverNightClameDate vs LastEOWClameDate) and the credit type in FeeQueueInMem (type 14=weekend, -14=overnight). |
| 14 | ErrorMessage | varchar(500) | YES | - | CODE-BACKED | SQL error message captured from the CATCH block's ERROR_MESSAGE() function. Documents the exact failure reason for each position. Used for root cause analysis and remediation of failed fee collection. |
| 15 | StatusID | int | YES | - | CODE-BACKED | Error status code from Trade.FeeNightProcess at time of failure. Always -1 in this table (only StatusID=-1 rows are copied here). Preserved for completeness and join-back to Trade.FeeNightProcess records. |
| 16 | Occurred | datetime | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp when this failure record was inserted into this table. Set to GETUTCDATE() by DEFAULT at the moment the bulk INSERT occurs (after the entire partition is processed). Not the time the fee processing attempt failed - that happened earlier in the batch loop. Used by Monitor.AlertFeeProcess_DataDog to detect recent failures (WHERE Occurred > DATEADD(hour, -10, @now)). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | History.Position_Active | Implicit | Position may have been closed by the time of fee processing; PayForFeeProcess updates History.Position_Active.EndOfWeekFee if Trade.PositionTbl returns 0 rows. |
| MirrorID | History.Mirror | Implicit | Copy-trade mirror relationship context for mirror positions. No FK constraint. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PayForFeeProcess | - | Writer | Sole writer: bulk-inserts all StatusID=-1 rows from Trade.FeeNightProcess after each partition completes processing |
| Monitor.AlertFeeProcess_DataDog | Occurred | Reader | Checks for recent rows during 03:00-05:00 UTC window to generate Datadog alerts |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.FeeNightProcessFail (table)
- no code-level dependencies (leaf table, error log)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PayForFeeProcess | Stored Procedure | Writes: bulk-inserts failed fee positions after each partition finishes |
| Monitor.AlertFeeProcess_DataDog | Stored Procedure | Reads: queries Occurred for recent failures during the nightly monitoring window |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FeeNightProcessFail | NONCLUSTERED | CID ASC, PositionID ASC, PartitionCol ASC, Occurred ASC | - | - | Active (FILLFACTOR=90, DATA_COMPRESSION=PAGE, partitioned on PS_PositionTbl) |

No clustered index. The NONCLUSTERED PK is partition-aligned with PS_PositionTbl. FILLFACTOR=90 leaves 10% page space for inserts. OPTIMIZE_FOR_SEQUENTIAL_KEY=ON reduces last-page insert contention under concurrent writes.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF (unnamed) | DEFAULT | Occurred = GETUTCDATE() - sets UTC timestamp of error log insertion |
| PK_FeeNightProcessFail | NONCLUSTERED PK | (CID, PositionID, PartitionCol, Occurred) - allows same position to appear multiple times if it fails on different nights |

---

## 8. Sample Queries

### 8.1 Recent fee processing failures (for incident investigation)

```sql
SELECT
    f.PositionID,
    f.CID,
    f.FeeInDollars,
    f.ErrorMessage,
    f.Fee,
    CASE WHEN f.Fee = 1 THEN 'Overnight' ELSE 'Weekend' END AS FeeType,
    f.Occurred,
    f.MirrorID,
    f.StatusID
FROM History.FeeNightProcessFail f WITH (NOLOCK)
WHERE f.Occurred >= DATEADD(HOUR, -24, GETUTCDATE())
ORDER BY f.Occurred DESC;
```

### 8.2 Most common error messages in the last 30 days

```sql
SELECT
    f.ErrorMessage,
    COUNT(*) AS FailureCount,
    COUNT(DISTINCT f.CID) AS AffectedCustomers,
    MIN(f.Occurred) AS FirstSeen,
    MAX(f.Occurred) AS LastSeen
FROM History.FeeNightProcessFail f WITH (NOLOCK)
WHERE f.Occurred >= DATEADD(DAY, -30, GETUTCDATE())
GROUP BY f.ErrorMessage
ORDER BY FailureCount DESC;
```

### 8.3 Total unrecovered fee amount from failed collections

```sql
SELECT
    CASE WHEN f.Fee = 1 THEN 'Overnight' ELSE 'Weekend' END AS FeeType,
    COUNT(*) AS FailedPositions,
    SUM(f.FeeInDollars) AS TotalUnrecoveredFeeUSD,
    MIN(f.Occurred) AS OldestFailure,
    MAX(f.Occurred) AS NewestFailure
FROM History.FeeNightProcessFail f WITH (NOLOCK)
GROUP BY f.Fee
ORDER BY TotalUnrecoveredFeeUSD DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (Trade.PayForFeeProcess, Monitor.AlertFeeProcess_DataDog) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.FeeNightProcessFail | Type: Table | Source: etoro/etoro/History/Tables/History.FeeNightProcessFail.sql*
