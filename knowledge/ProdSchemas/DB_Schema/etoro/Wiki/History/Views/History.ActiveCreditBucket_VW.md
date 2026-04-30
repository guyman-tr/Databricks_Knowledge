# History.ActiveCreditBucket_VW

> Combined credit ledger view merging the persistent credit archive (History.ActiveCredit) with the in-memory staging buffer (History.ActiveCreditRecentMemoryBucket) using UNION (deduplicated) - provides a consistent 35-column credit interface that includes credits written in the current flush cycle not yet moved to the permanent table, with PartitionCol hardcoded to 0 for memory bucket rows.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | CreditID (bigint) |
| **Partition** | N/A (view - base table partitioned by Occurred) |
| **Indexes** | N/A (view - base table indexes used) |

---

## 1. Business Meaning

History.ActiveCreditBucket_VW is the credit read interface that combines both pools of active credit data: the persistent disk archive in `History.ActiveCredit` and the in-memory staging buffer in `History.ActiveCreditRecentMemoryBucket`.

The eToro credit ledger has a two-tier write architecture: credits are first written to the in-memory table (via `Customer.SetBalanceInsertCredit_Native` at native-compilation speed), then periodically flushed to the persistent disk table (via `Trade.InsertActiveCredit` using DELETE...OUTPUT INTO). During the flush interval, recent credits exist only in the in-memory buffer. Queries against History.ActiveCredit alone would miss these pending-flush records.

History.ActiveCreditBucket_VW bridges this gap by UNIONing both sources, ensuring all credit events are visible regardless of flush status.

**Key behavior: UNION (not UNION ALL)**. The view uses UNION rather than UNION ALL, which performs implicit deduplication. Since the DELETE...OUTPUT INTO flush is atomic (a row is either in the buffer OR in ActiveCredit_BIGINT, never in both), UNION deduplication is theoretically unnecessary. However, using UNION provides a safety net against edge cases in the flush pipeline. The cost is a slightly more expensive query plan (requires a SORT/HASH-DISTINCT operation).

**PartitionCol for memory bucket rows**: History.ActiveCreditRecentMemoryBucket does not have a native PartitionCol column (added to the persistent table for hash-partitioned JOINs). The view hardcodes `0 AS [PartitionCol]` for these rows. This means consumers that rely on PartitionCol for JOIN optimization will treat all memory bucket rows as being in partition bucket 0.

Four consumers reference this view: Customer.SetBalance (validation), BackOffice.GetMirrorHistory, Billing.PSPMatchToEtoro2, Customer.PostMIMOOperations/PostMIMOOperationsDebug.

---

## 2. Business Logic

### 2.1 UNION Architecture - Deduplicated Dual-Source Credit Read

**What**: Combines the persistent credit archive with the in-memory buffer using UNION (deduplicating).

**Columns/Parameters Involved**: All 35 columns including PartitionCol

**Rules**:
- Branch 1: `History.ActiveCredit` - all 35 columns, all rows from the persistent BIGINT-keyed credit archive. PartitionCol = native value from ActiveCredit_BIGINT.
- Branch 2: `History.ActiveCreditRecentMemoryBucket` - 35 columns with `0 AS [PartitionCol]`. Provides visibility into credits not yet flushed to disk.
- UNION (not UNION ALL): duplicate rows across branches are eliminated. In normal operation there are no duplicates (atomic flush ensures mutual exclusivity), but UNION provides a safety net.
- All column names are identical between the two sources (no aliasing needed), except PartitionCol which is hardcoded to 0 for the memory bucket branch.

**Diagram**:
```
History.ActiveCredit (35 cols, all persistent credits, native PartitionCol)
  |
UNION
  |
History.ActiveCreditRecentMemoryBucket (35 cols, pending-flush credits, 0 as PartitionCol)
  |
  v
History.ActiveCreditBucket_VW (35 cols - deduplicated, complete current credit state)
```

### 2.2 PartitionCol = 0 for In-Memory Rows

**What**: History.ActiveCreditRecentMemoryBucket does not have a PartitionCol column; the view substitutes 0.

**Columns/Parameters Involved**: `PartitionCol`

**Rules**:
- History.ActiveCredit_BIGINT has PartitionCol = CreditID%{N} (a hash bucket for partitioned JOINs)
- History.ActiveCreditRecentMemoryBucket does not have this column (it is a staging table, not indexed for partition JOINs)
- The view substitutes `0 AS [PartitionCol]` for all memory bucket rows
- Consumers that filter on PartitionCol (e.g., for hash-partitioned JOINs) will always see memory bucket rows when PartitionCol = 0
- This differs from History.ActiveCreditView, which substitutes NULL for PartitionCol in memory bucket rows

### 2.3 Comparison with Related Credit Views

**What**: Multiple similar views exist in the credit abstraction hierarchy with subtle differences.

| View | Sources | Operator | PartitionCol (memory rows) | Column count |
|------|---------|----------|--------------------------|-------------|
| History.ActiveCredit | ActiveCredit_BIGINT only | SELECT | native | 35 |
| History.ActiveCreditBucket_VW | ActiveCredit + MemoryBucket | UNION | 0 | 35 |
| History.ActiveCreditView | ActiveCredit + MemoryBucket | UNION ALL | NULL | 35 |
| History.ActiveCreditSafty | ActiveCredit only | SELECT | not included | 26 |
| History.Credit | ActiveCredit + 75+ archive tables | UNION ALL | null/native | 35 |

---

## 3. Data Overview

Data sample from History.ActiveCredit branch (most recent, as of 2026-03-21):

| CreditID | CID | CreditTypeID | Credit | Payment | Occurred |
|----------|-----|-------------|--------|---------|----------|
| 2174752045 | 24860041 | 1 (Deposit) | 400 | 100 | 2026-03-21 |
| 2174752044 | 25006152 | 1 (Deposit) | 300 | 100 | 2026-03-21 |
| 2174752041 | 25158719 | 3 (Open Position) | 232.93 | -20.19 | 2026-03-21 |

Memory bucket rows (if flush is pending): visible here but not in History.ActiveCredit. In normal operation the memory bucket is small (a few hundred to a few thousand rows between flush cycles).

---

## 4. Elements

35 output columns - identical in name and type to History.ActiveCredit's 35 columns. All element descriptions are inherited from History.ActiveCredit_BIGINT documentation. Key distinctions for this view:

| # | Element | Type | Nullable | Confidence | Notes |
|---|---------|------|----------|------------|-------|
| 1 | CreditID | bigint | NO | CODE-BACKED | Ledger event PK. bigint throughout (IDENTITY from BIGINT table; memory bucket also assigns bigint CreditIDs). Persistent archive has CreditIDs in billions range; memory bucket IDs are recent (same sequence). |
| 2 | CID | int | NO | CODE-BACKED | Customer ID. Both branches guarantee non-NULL CID. |
| 3 | CreditTypeID | int | NO | CODE-BACKED | Type of financial event. See ActiveCredit_BIGINT for full value map (1=Deposit, 2=Cashout, 3=OpenPosition, 4=ClosePosition, 6=Compensation, 7=Bonus, etc.). |
| 4-30 | (PositionID through StocksOrderID) | Various | YES | CODE-BACKED | Standard credit columns. Same as History.ActiveCredit. See ActiveCredit_BIGINT.md for full descriptions. |
| 31 | PartitionCol | int | YES | CODE-BACKED | Hash bucket for partitioned JOINs. Native value for History.ActiveCredit rows; hardcoded 0 for History.ActiveCreditRecentMemoryBucket rows. |
| 32-35 | OriginalPositionID, SubCreditTypeID, DepositRollbackID, InterestMonthlyID | Various | YES | CODE-BACKED | Newer columns added to the credit schema. Present with native values in ActiveCredit rows; present (with original values) in memory bucket rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (branch 1) | History.ActiveCredit | View (UNION branch) | Persistent credit archive (35 cols) |
| (branch 2) | History.ActiveCreditRecentMemoryBucket | View (UNION branch) | In-memory staging buffer (35 cols, 0 as PartitionCol) |
| CreditTypeID | Dictionary.CreditType (implied) | Implicit FK | Credit event type |
| CID | Customer.Customer | Implicit FK | Account owner |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalance | CreditID/CID | Read (validation) | Validates credit was written before proceeding |
| BackOffice.GetMirrorHistory | CreditID/MirrorID | Read | Mirror relationship credit history |
| Billing.PSPMatchToEtoro2 | CreditID/DepositID | Read | PSP-to-eToro payment reconciliation |
| Customer.PostMIMOOperations | CreditID/CID | Read | Post-MIMO operation credit verification |
| Customer.PostMIMOOperationsDebug | CreditID/CID | Read | Debug variant of MIMO operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ActiveCreditBucket_VW (view)
|- History.ActiveCredit (view)
|    +- History.ActiveCredit_BIGINT (table - partitioned, 7 indexes)
|         Written by: Trade.InsertActiveCredit (flush from memory bucket)
|
+- History.ActiveCreditRecentMemoryBucket (table - memory-optimized, In-Memory OLTP)
     Written by: Customer.SetBalanceInsertCredit_Native (native compiled)
     Flushed by: Trade.InsertActiveCredit / Trade.InsertActiveCreditPartition
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit | View | UNION branch 1 - persistent credit archive |
| History.ActiveCreditRecentMemoryBucket | Table | UNION branch 2 - in-memory staging buffer |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalance | Stored Procedure | Credit validation after write |
| BackOffice.GetMirrorHistory | Stored Procedure | Mirror credit history lookup |
| Billing.PSPMatchToEtoro2 | Stored Procedure | PSP reconciliation |
| Customer.PostMIMOOperations | Stored Procedure | Post-MIMO credit verification |
| Customer.PostMIMOOperationsDebug | Stored Procedure | Debug variant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. History.ActiveCredit queries benefit from History.ActiveCredit_BIGINT indexes:
- CLUSTERED on (CID, Occurred DESC) for per-customer credit queries
- NONCLUSTERED PK on CreditID
- Filtered NC for WithdrawID lookups
- DWH covering index for extract queries

History.ActiveCreditRecentMemoryBucket branch: only the NONCLUSTERED PK on CreditID is available (memory-optimized table).

### 7.2 Performance Note

UNION (vs UNION ALL) requires an implicit deduplication pass - the query optimizer must compute distinct rows across both branches. For large credit lookups by CID or date range, this may add overhead vs UNION ALL. History.ActiveCreditView uses UNION ALL for the same combined dataset. If consumers need the memory bucket data without deduplication overhead, History.ActiveCreditView is the alternative.

---

## 8. Sample Queries

### 8.1 Check if a credit exists in either the persistent or in-memory store
```sql
SELECT
    ac.CreditID,
    ac.CID,
    ac.CreditTypeID,
    ac.Credit,
    ac.Payment,
    ac.Occurred
FROM History.ActiveCreditBucket_VW ac WITH (NOLOCK)
WHERE ac.CID = 14952810
  AND ac.CreditTypeID IN (3, 4)  -- OpenPosition, ClosePosition
ORDER BY ac.Occurred DESC;
```

### 8.2 Verify a specific credit was written (including pending-flush credits)
```sql
SELECT TOP 1
    ac.CreditID,
    ac.DepositID,
    ac.CreditTypeID,
    ac.Payment,
    ac.Occurred
FROM History.ActiveCreditBucket_VW ac WITH (NOLOCK)
WHERE ac.CID = @CID
  AND ac.CreditTypeID = 1  -- Deposit
ORDER BY ac.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for History.ActiveCreditBucket_VW. Business context inherited from History.ActiveCredit and History.ActiveCreditRecentMemoryBucket documentation.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.9/10 (Elements: 8.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 35 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 consumers found | App Code: 0 repos | Corrections: 0 applied*
*Object: History.ActiveCreditBucket_VW | Type: View | Source: etoro/etoro/History/Views/History.ActiveCreditBucket_VW.sql*
