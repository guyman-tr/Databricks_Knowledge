# History.ActiveCreditView

> Combined credit ledger view merging the persistent credit archive (History.ActiveCredit) with the in-memory staging buffer (History.ActiveCreditRecentMemoryBucket) using UNION ALL (no deduplication) - exposes all 35 columns with NULL for PartitionCol on memory bucket rows, providing the fastest combined credit view for batch fee and interest calculation procedures.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | CreditID (bigint) |
| **Partition** | N/A (view - base table partitioned) |
| **Indexes** | N/A (view - base table indexes used) |

---

## 1. Business Meaning

History.ActiveCreditView is the UNION ALL variant of the combined credit view that merges the persistent disk archive (History.ActiveCredit) with the in-memory staging buffer (History.ActiveCreditRecentMemoryBucket). It provides the same two-source coverage as History.ActiveCreditBucket_VW but uses UNION ALL instead of UNION, and substitutes NULL (not 0) for PartitionCol on memory bucket rows.

The view serves the same fundamental need as History.ActiveCreditBucket_VW: ensuring that procedures can see credits that were written to the in-memory buffer but not yet flushed to the persistent disk table. This is critical for real-time financial operations (bonus deduplication, balance validation) and for batch jobs that run before a flush cycle completes.

**UNION ALL vs UNION distinction (vs ActiveCreditBucket_VW)**:
- History.ActiveCreditBucket_VW: UNION - implicit deduplication (safer, slightly slower)
- History.ActiveCreditView: UNION ALL - no deduplication (faster, assumes no duplicates across branches)
Both are safe in normal operation since the DELETE...OUTPUT INTO flush is atomic (a CreditID exists in only one source at any given time), but UNION ALL is more performant because it skips the deduplication pass.

**PartitionCol = NULL vs 0 (vs ActiveCreditBucket_VW)**:
- History.ActiveCreditBucket_VW: `0 AS [PartitionCol]` for memory bucket rows
- History.ActiveCreditView: `NULL` for PartitionCol on memory bucket rows
The difference matters for consumers that do `WHERE PartitionCol = 0` (to process a specific hash bucket) - they would see memory bucket rows in Bucket_VW but not in ActiveCreditView.

---

## 2. Business Logic

### 2.1 UNION ALL Architecture - Two-Source Credit Interface

**What**: Combines the persistent credit archive and in-memory staging buffer using UNION ALL (no deduplication).

**Columns/Parameters Involved**: All 35 columns including PartitionCol (NULL for memory bucket)

**Rules**:
- Branch 1: `History.ActiveCredit` - all 35 columns with native PartitionCol values. All permanently flushed credits.
- Branch 2: `History.ActiveCreditRecentMemoryBucket` - all 35 columns with `NULL AS PartitionCol`. All pending-flush credits.
- UNION ALL: no deduplication. Relies on the mutual exclusivity guarantee of the atomic flush pipeline.
- Result: all credit events across both tables, ordered by the query (no implicit ordering from view).

**Diagram**:
```
History.ActiveCredit (35 cols, native PartitionCol)
  |
UNION ALL
  |
History.ActiveCreditRecentMemoryBucket (35 cols, NULL as PartitionCol)
  |
  v
History.ActiveCreditView (35 cols, complete current credit state, UNION ALL)
```

### 2.2 PartitionCol = NULL for In-Memory Rows

**What**: PartitionCol is NULL for all History.ActiveCreditRecentMemoryBucket rows in this view.

**Columns/Parameters Involved**: `PartitionCol`

**Rules**:
- For persistent rows (from History.ActiveCredit): PartitionCol = native value from History.ActiveCredit_BIGINT
- For memory bucket rows: PartitionCol = NULL (unlike History.ActiveCreditBucket_VW which uses 0)
- Consumers that filter `WHERE PartitionCol = 0` will NOT see memory bucket rows in this view
- Consumers that filter `WHERE PartitionCol = N` or do hash-partitioned JOINs should use History.ActiveCreditBucket_VW if they also need memory bucket coverage

### 2.3 Credit View Family Comparison

| View | Sources | Operator | PartitionCol (memory rows) | Speed |
|------|---------|----------|--------------------------|-------|
| History.ActiveCredit | Persistent only | SELECT | native | Fastest |
| History.ActiveCreditSafty | Persistent only | SELECT | not included | Fast (26 cols) |
| History.ActiveCreditView | Persistent + Memory | UNION ALL | NULL | Fast |
| History.ActiveCreditBucket_VW | Persistent + Memory | UNION | 0 | Slower (dedup) |
| History.Credit | Persistent + 75+ archives | UNION ALL | null/native | Slowest (full history) |

---

## 3. Data Overview

Same data as History.ActiveCredit (persistent rows) plus any pending-flush credits from History.ActiveCreditRecentMemoryBucket. In normal operation the memory bucket contains hundreds to thousands of recent credits pending the next flush cycle.

Sample from History.ActiveCredit branch (most recent, 2026-03-21):

| CreditID | CID | CreditTypeID | Credit | Payment | Occurred | PartitionCol |
|----------|-----|-------------|--------|---------|----------|-------------|
| 2174752045 | 24860041 | 1 (Deposit) | 400 | 100 | 2026-03-21 | native value |
| 2174752041 | 25158719 | 3 (Open Position) | 232.93 | -20.19 | 2026-03-21 | native value |

Memory bucket rows would appear with PartitionCol = NULL and recent CreditIDs.

---

## 4. Elements

35 output columns - same as History.ActiveCredit. All element descriptions inherited from History.ActiveCredit_BIGINT documentation. Key element distinctions for this view:

| # | Element | Type | Nullable | Confidence | Notes |
|---|---------|------|----------|------------|-------|
| 1 | CreditID | bigint | NO | CODE-BACKED | Unique across both sources due to shared IDENTITY sequence (both tables use the same sequence). |
| 2-30 | (CID through StocksOrderID) | Various | Various | CODE-BACKED | Standard credit columns - same as History.ActiveCredit. See ActiveCredit_BIGINT.md for full descriptions. |
| 31 | PartitionCol | int | YES | CODE-BACKED | Native value for History.ActiveCredit rows; NULL for History.ActiveCreditRecentMemoryBucket rows. NULL distinguishes memory bucket rows when needed. |
| 32-35 | OriginalPositionID, SubCreditTypeID, DepositRollbackID, InterestMonthlyID | Various | YES | CODE-BACKED | Newer columns; present with native values in both branches. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (branch 1) | History.ActiveCredit | View (UNION ALL branch) | Persistent credit archive (35 cols) |
| (branch 2) | History.ActiveCreditRecentMemoryBucket | View (UNION ALL branch) | In-memory staging buffer (35 cols, NULL PartitionCol) |
| CreditTypeID | Dictionary.CreditType (implied) | Implicit FK | Credit event type |
| CID | Customer.Customer | Implicit FK | Account owner |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetPositionsForFeeProcess | CID/CreditTypeID | Read | Fee calculation - needs current credits including pending-flush |
| Trade.GetPositionsForFeeBulkGeneral | CID/CreditTypeID | Read | Bulk fee calculation |
| Trade.GetPositionsForFeeBulkGeneral_Aus | CID/CreditTypeID | Read | Australian fee calculation |
| Trade.InterestGetDailyRawData | CID/Credit/Occurred | Read | Daily interest raw data |
| Trade.InterestGetDailyRawDataTest | CID/Credit/Occurred | Read | Test variant of interest calculation |
| Trade.InterestGetDailyRawDataNEWELAD | CID/Credit/Occurred | Read | Interest calculation variant |
| Trade.ReportWrongDataInHistoryCredit | CreditID | Read | Data quality reporting |
| Trade.ReportWrongDataInHistoryCredit_NewElad | CreditID | Read | Data quality variant |
| BackOffice.UpsertIntoAggregationTables | CID/CreditTypeID | Read | BO aggregation tables |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ActiveCreditView (view)
|- History.ActiveCredit (view)
|    +- History.ActiveCredit_BIGINT (table - partitioned)
|
+- History.ActiveCreditRecentMemoryBucket (table - memory-optimized)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit | View | UNION ALL branch 1 - persistent credit archive |
| History.ActiveCreditRecentMemoryBucket | Table | UNION ALL branch 2 - in-memory staging buffer |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionsForFeeProcess | Stored Procedure | Fee calculation |
| Trade.GetPositionsForFeeBulkGeneral | Stored Procedure | Bulk fee calculation |
| Trade.GetPositionsForFeeBulkGeneral_Aus | Stored Procedure | AU fee calculation |
| Trade.InterestGetDailyRawData | Stored Procedure | Interest calculation |
| Trade.InterestGetDailyRawDataTest | Stored Procedure | Interest calculation test |
| Trade.InterestGetDailyRawDataNEWELAD | Stored Procedure | Interest calculation variant |
| Trade.ReportWrongDataInHistoryCredit | Stored Procedure | Data quality report |
| Trade.ReportWrongDataInHistoryCredit_NewElad | Stored Procedure | Data quality variant |
| BackOffice.UpsertIntoAggregationTables | Stored Procedure | Aggregation maintenance |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Queries benefit from History.ActiveCredit_BIGINT indexes (for branch 1) and History.ActiveCreditRecentMemoryBucket's NONCLUSTERED PK (for branch 2).

---

## 8. Sample Queries

### 8.1 Get complete credit history for a customer including pending-flush records
```sql
SELECT
    av.CreditID,
    av.CreditTypeID,
    av.Credit,
    av.Payment,
    av.PositionID,
    av.Occurred,
    CASE WHEN av.PartitionCol IS NULL THEN 'Memory (pending flush)' ELSE 'Persistent' END AS Source
FROM History.ActiveCreditView av WITH (NOLOCK)
WHERE av.CID = 14952810
ORDER BY av.Occurred DESC;
```

### 8.2 Check for bonus deduplication (including in-memory buffer)
```sql
SELECT COUNT(*) AS BonusGrantCount
FROM History.ActiveCreditView av WITH (NOLOCK)
WHERE av.CID = @CID
  AND av.CreditTypeID = 7  -- Bonus
  AND av.CampaignID = @CampaignID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for History.ActiveCreditView. Business context inherited from History.ActiveCredit and History.ActiveCreditRecentMemoryBucket documentation.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 35 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 9 consumers found | App Code: 0 repos | Corrections: 0 applied*
*Object: History.ActiveCreditView | Type: View | Source: etoro/etoro/History/Views/History.ActiveCreditView.sql*
