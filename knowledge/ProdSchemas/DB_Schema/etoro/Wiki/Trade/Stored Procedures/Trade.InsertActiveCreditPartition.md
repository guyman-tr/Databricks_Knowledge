# Trade.InsertActiveCreditPartition

> Continuously flushes a specific modulo partition of ActiveCredit records from the in-memory recent-bucket into permanent history using a WHILE loop, enabling parallel drainage across 10 concurrent partition threads.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Numrows INT (batch size), @Mod INT (partition 0-9) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertActiveCreditPartition is the **parallelized, continuous version** of `Trade.InsertActiveCredit`. It migrates records from `History.ActiveCreditRecentMemoryBucket` (in-memory high-speed buffer) into `History.ActiveCredit_BIGINT` (permanent disk storage), but does so for only one of 10 modulo partitions at a time (`CreditID % 10 = @Mod`), enabling up to 10 concurrent executions without interference.

This SP exists to handle high-throughput credit insertion scenarios. The in-memory bucket fills rapidly during peak trading hours; a single-threaded flush (InsertActiveCredit) may not drain fast enough. By running 10 parallel instances - each handling a different modulo partition (@Mod 0 through 9) - the system achieves approximately 10x throughput. Each partition is independent (no CreditID overlap between partitions), so there are no locking conflicts.

Data flow: The WHILE loop continues as long as the last DELETE affected any rows (`@rc > 0`). Within each iteration, it moves @Numrows records for the assigned partition starting from the current @i, then advances @i by @Numrows. This continues until the partition is fully drained.

---

## 2. Business Logic

### 2.1 Modulo Partitioning Strategy

**What**: Routes each CreditID to one of 10 independent partition lanes by CreditID mod 10.

**Columns/Parameters Involved**: `@Mod`, `CreditID`

**Rules**:
- `WHERE CreditID % 10 = @Mod` - restricts this SP instance to exactly 1/10th of all records
- @Mod range: 0-9 (10 partitions total)
- Running EXEC InsertActiveCreditPartition @Numrows=N, @Mod=0 through @Mod=9 in 10 parallel sessions covers all records
- No CreditID can appear in two different partition lanes - partitions are fully disjoint
- CreditID is used as the partitioning key (not CID) ensuring even distribution since CreditID is a monotonic sequence

**Diagram**:
```
History.ActiveCreditRecentMemoryBucket
  CreditID=1000 (1000%10=0) -> Session with @Mod=0
  CreditID=1001 (1001%10=1) -> Session with @Mod=1
  CreditID=1002 (1002%10=2) -> Session with @Mod=2
  ...
  CreditID=1009 (1009%10=9) -> Session with @Mod=9
  CreditID=1010 (1010%10=0) -> Session with @Mod=0
  ...

Parallel execution (10 sessions):
  Session 1: EXEC InsertActiveCreditPartition @Numrows=5000, @Mod=0  -> drains mod-0 records
  Session 2: EXEC InsertActiveCreditPartition @Numrows=5000, @Mod=1  -> drains mod-1 records
  ...
  Session 10: EXEC InsertActiveCreditPartition @Numrows=5000, @Mod=9 -> drains mod-9 records
```

### 2.2 WHILE Loop - Continuous Drain Until Empty

**What**: Unlike InsertActiveCredit (single pass), this SP loops until its partition is fully drained.

**Columns/Parameters Involved**: `@Numrows`, `@i`, `@rc`

**Rules**:
- `@i = MIN(CreditID) WHERE CreditID%10=@Mod` - starting point for this partition
- Loop continues while `@rc > 0` (last iteration moved at least 1 record)
- Each iteration: DELETE @Numrows records, capture @@ROWCOUNT into @rc
- `@i += @Numrows` advances the range for next iteration
- `PRINT CAST(@rc AS VARCHAR)` outputs row count to the SQL messages stream (diagnostic only)
- When the partition is empty, `@rc = 0` and the loop exits

### 2.3 Columns Migrated (Identical to InsertActiveCredit)

Both InsertActiveCredit and InsertActiveCreditPartition move the exact same 34 columns (full schema of History.ActiveCredit_BIGINT). See `Trade.InsertActiveCredit` documentation for column-level descriptions.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Numrows | INT | NO | - | CODE-BACKED | Batch size per iteration within the WHILE loop. Controls how many consecutive CreditIDs are processed per loop iteration. Balances transaction size against throughput - too small means many loop iterations; too large means long-running individual transactions. |
| 2 | @Mod | INT | NO | - | CODE-BACKED | The modulo partition this SP instance processes. Must be 0-9 to correspond to CreditID%10 values. Running instances with @Mod 0-9 in parallel provides full parallel coverage of all records without overlap. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads/deletes from) | History.ActiveCreditRecentMemoryBucket | DELETER (cross-schema) | Source in-memory buffer; records are permanently removed when migrated |
| (inserts into) | History.ActiveCredit_BIGINT | WRITER (cross-schema) | Permanent destination table for all migrated credit records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job (external) | EXEC Trade.InsertActiveCreditPartition | Scheduled parallel calls | Typically called as 10 parallel executions (@Mod 0-9) by a SQL Agent job or orchestration layer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertActiveCreditPartition (procedure)
├── History.ActiveCreditRecentMemoryBucket (table - cross-schema, source)
└── History.ActiveCredit_BIGINT (table - cross-schema, destination)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCreditRecentMemoryBucket | Table (cross-schema) | Source table; reads MIN(CreditID) for partition and DELETEs migrated records |
| History.ActiveCredit_BIGINT | Table (cross-schema) | Destination; receives all deleted records via OUTPUT clause |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External SQL Agent Job | Scheduled job | Calls this SP in 10 parallel instances (@Mod=0 through 9) to fully drain the memory bucket |
| Trade.InsertActiveCredit | Procedure | Companion SP (single-pass, no loop, no partition) - see also |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @Mod range | Parameter convention | Must be 0-9 to match CreditID%10; values outside 0-9 will find 0 rows and exit immediately |
| NOLOCK on MIN query | Hint | Initial @i read is approximate; safe because CreditIDs are monotonically increasing |
| Loop exit condition | @rc = @@ROWCOUNT | Loop exits when the last batch affected 0 rows - partition is empty or no more CreditIDs in range |

---

## 8. Sample Queries

### 8.1 Run a full parallel drain across all 10 partitions (individual sessions)

```sql
-- Run each line in a separate SSMS session for parallel execution
EXEC Trade.InsertActiveCreditPartition @Numrows = 5000, @Mod = 0
-- EXEC Trade.InsertActiveCreditPartition @Numrows = 5000, @Mod = 1
-- ... through @Mod = 9
```

### 8.2 Check partition distribution before running

```sql
-- See how many records exist per modulo partition
SELECT CreditID % 10 AS Partition, COUNT(*) AS RecordCount
FROM History.ActiveCreditRecentMemoryBucket WITH (NOLOCK)
GROUP BY CreditID % 10
ORDER BY Partition
```

### 8.3 Monitor progress during migration

```sql
-- Check remaining records in the memory bucket during migration
SELECT COUNT(*) AS RemainingInBucket,
       MIN(CreditID) AS OldestPending
FROM History.ActiveCreditRecentMemoryBucket WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (InsertActiveCredit - companion SP) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertActiveCreditPartition | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertActiveCreditPartition.sql*
